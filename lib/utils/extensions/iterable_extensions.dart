extension SafeAccess<T> on Iterable<T> {
  T? safeElementAt(int index){
    try {
      return elementAt(index);
    } on RangeError {
      return null;
    }
  }
}