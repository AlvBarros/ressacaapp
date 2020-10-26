class ChatState {
  static final notConnected = NotConnected();
  static final loading = Loading();
  static final connected = Connected();
  final _currentState = "uninitialized";

  bool equals(ChatState state) {
    return this._currentState == state._currentState;
  }
}
class NotConnected extends ChatState { final _currentState = "notconnected"; }
class Loading extends ChatState { final _currentState = "loading"; }
class Connected extends ChatState { final _currentState = "connected"; }