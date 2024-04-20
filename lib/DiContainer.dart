class DiContainer {
  static Map<String, Object> instances = new Map<String, Object>();
  static void setInstance<T>(T instance) {
    instances[T.toString()] = instance as Object;
  }

  static T resolve<T>() {
    return instances[T.toString()] as T;
  }
}
