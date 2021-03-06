// Copyright (C) 2019  Wilko Manger
//
// This file is part of Pattle.
//
// Pattle is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Pattle is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with Pattle.  If not, see <https://www.gnu.org/licenses/>.

import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../chat_order/bloc.dart';

import '../../../models/chat.dart';

import '../../../matrix.dart';

import 'event.dart';
import 'state.dart';

export 'state.dart';
export 'event.dart';

class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  final Matrix _matrix;
  final ChatOrderBloc _chatOrderBloc;

  StreamSubscription _subscription;
  ChatsBloc(this._matrix, this._chatOrderBloc) {
    _matrix.userAvaible.then((_) {
      add(RefreshChats());
      _subscription = _matrix.user.updates.listen((update) {
        add(RefreshChats());
      });
    });
  }

  Future<List<Chat>> _getChats() async {
    final chats = _matrix.chats.values.toList();

    chats.sort((a, b) {
      if (a.room.highlightedUnreadNotificationCount > 0 &&
          b.room.highlightedUnreadNotificationCount <= 0) {
        return 1;
      } else if (a.room.highlightedUnreadNotificationCount <= 0 &&
          b.room.highlightedUnreadNotificationCount > 0) {
        return -1;
      } else if (a.room.totalUnreadNotificationCount > 0 &&
          b.room.totalUnreadNotificationCount <= 0) {
        return 1;
      } else if (a.room.totalUnreadNotificationCount <= 0 &&
          b.room.totalUnreadNotificationCount > 0) {
        return -1;
      } else if (a.latestMessageForSorting != null &&
          b.latestMessageForSorting != null) {
        return a.latestMessageForSorting.event.time.compareTo(
          b.latestMessageForSorting.event.time,
        );
      } else if (a.latestMessageForSorting != null &&
          b.latestMessageForSorting == null) {
        return 1;
      } else if (a.latestMessageForSorting == null &&
          b.latestMessageForSorting != null) {
        return -1;
      } else {
        return 0;
      }
    });

    return chats.reversed.toList();
  }

  Future<ChatsState> _loadChats() async {
    final chats = await _getChats();

    final personalChats = chats.where((chat) => !chat.isChannel).toList();
    final publicChats = chats.where((chat) => chat.isChannel).toList();

    _chatOrderBloc.add(
      UpdateChatOrder(
        personal: personalChats,
        public: publicChats,
      ),
    );

    return ChatsLoaded(personal: personalChats, public: publicChats);
  }

  @override
  ChatsState get initialState => ChatsLoading();

  @override
  Stream<ChatsState> mapEventToState(ChatsEvent event) async* {
    if (event is RefreshChats) {
      yield await _loadChats();
    }

    final state = this.state;
    if (event is LoadMoreChats && state is ChatsLoaded) {
      final ids = event.personal
          ? _chatOrderBloc.state.personal
          : _chatOrderBloc.state.public;
      final currentlyShownChats =
          event.personal ? state.personal : state.public;

      final currentlyShownIds = currentlyShownChats.map((c) => c.room.id);

      final next10Ids =
          ids.keys.where((id) => !currentlyShownIds.contains(id)).take(10);

      _matrix.user.rooms.load(roomIds: next10Ids);
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}
