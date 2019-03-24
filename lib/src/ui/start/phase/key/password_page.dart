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
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:pattle/src/ui/resources/localizations.dart';
import 'package:pattle/src/ui/start/advanced_page.dart';
import 'package:pattle/src/ui/start/start_bloc.dart';

class PasswordPage extends StatelessWidget {

  String password;

  void _next() {
    start.login(password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              AppLocalizations.of(context).enterPassword,
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 16),
            StreamBuilder<LoginState>(
              stream: start.loginStream,
              builder: (BuildContext context, AsyncSnapshot<LoginState> snapshot) {
                String errorText;

                if (snapshot.hasError) {
                  if (snapshot.error is ForbiddenException) {
                    errorText = l(context).wrongPassword;
                  } else {
                    debugPrint(snapshot.error.toString());
                    debugPrintStack();
                    errorText = l(context).unknownErrorOccured;
                  }
                } else {
                  errorText = null;
                }

                return TextField(
                  autofocus: true,
                  onChanged: (value) {
                    password = value;
                  },
                  onEditingComplete: () {
                    _next();
                  },
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    labelText: AppLocalizations.of(context).password,
                    errorText: errorText
                  )
                );
                }
            ),
            SizedBox(height: 16),
            StreamBuilder<LoginState>(
              stream: start.loginStream,
              builder: (BuildContext context, AsyncSnapshot<LoginState> snapshot) {
                print("snapshot.data: ${snapshot.data}");
                final isTrying = snapshot.data == LoginState.trying;
                var onPressed;

                if (!isTrying) {
                  onPressed = () {
                    _next();
                  };
                } else {
                  onPressed = null;
                }

                return RaisedButton(
                  onPressed: onPressed,
                  child: Text(AppLocalizations.of(context).login.toUpperCase())
                );
              }
            )
          ],
        )
      ),
    );
  }
}