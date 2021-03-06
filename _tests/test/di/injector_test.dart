// ignore_for_file: invalid_use_of_protected_member
@TestOn('browser')
import 'package:angular/di.dart';
import 'package:angular/src/di/injector/hierarchical.dart';
import 'package:angular/src/di/injector/injector.dart';
import 'package:test/test.dart';
import 'package:angular/src/di/reflector.dart' as reflector;

void main() {
  group('Injector', () {
    test('.get should delegate token to .inject', () {
      final injector = new CaptureInjectInjector();
      injector.get(ExampleService);
      expect(injector.lastToken, ExampleService);
      expect(injector.lastOrElse, throwsNotFound);
    });

    group('.get should delegate', () {
      CaptureInjectInjector injector;

      setUp(() => injector = new CaptureInjectInjector());

      test('token to .inject', () {
        injector.get(ExampleService);
        expect(injector.lastToken, ExampleService);
        expect(injector.lastOrElse, throwsNotFound);
      });

      test('orElse to .inject (partially, not API compatible)', () {
        injector.get(ExampleService, #customValue);
        expect(injector.lastToken, ExampleService);
        expect(injector.lastOrElse, isNot(throwsNotFound));
        expect(injector.lastOrElse(null, null), #customValue);
      });
    });

    group('.empty', () {
      HierarchicalInjector i;

      test('should throw by default', () {
        i = new Injector.empty();
        expect(() => i.get(ExampleService), throwsArgumentError);
        expect(() => i.inject(token: ExampleService), throwsArgumentError);
        expect(() => i.injectFromSelf(ExampleService), throwsArgumentError);
        expect(() => i.injectFromAncestry(ExampleService), throwsArgumentError);
        expect(() => i.injectFromParent(ExampleService), throwsArgumentError);
      });

      test('should use orElse if provided', () {
        i = new Injector.empty();
        customOrElse(_, __) => 123;
        expect(i.get(ExampleService, 123), 123);
        expect(i.inject(token: ExampleService, orElse: customOrElse), 123);
        expect(i.injectFromSelf(ExampleService, orElse: customOrElse), 123);
        expect(i.injectFromAncestry(ExampleService, orElse: customOrElse), 123);
        expect(i.injectFromParent(ExampleService, orElse: customOrElse), 123);
      });

      test('should fallback to the parent injector if provided', () {
        final parent = new Injector.map({ExampleService: 123});
        i = new Injector.empty(parent);
        expect(i.get(ExampleService), 123);
        expect(i.inject(token: ExampleService), 123);
        expect(() => i.injectFromSelf(ExampleService), throwsArgumentError);
        expect(i.injectFromAncestry(ExampleService), 123);
        expect(i.injectFromParent(ExampleService), 123);
      });

      test('should return itself if Injector is passed', () {
        i = new Injector.empty();
        expect(i.get(Injector), i);
      });
    });

    group('.map', () {
      HierarchicalInjector i;

      test('should return a provided key-value pair', () {
        i = new Injector.map({ExampleService: 123});
        expect(i.get(ExampleService), 123);
        expect(i.inject(token: ExampleService), 123);
        expect(i.injectFromSelf(ExampleService), 123);
        expect(() => i.injectFromAncestry(ExampleService), throwsArgumentError);
        expect(() => i.injectFromParent(ExampleService), throwsArgumentError);
      });

      test('should return itself if Injector is passed', () {
        expect(i.get(Injector), i);
      });
    });

    group('.slowReflective', () {
      Injector i;

      setUpAll(() {
        reflector.registerFactory(ExampleService, () => new ExampleService());
        reflector.registerFactory(ExampleService2, () => new ExampleService2());
        reflector.registerDependencies(createListWith, [
          [String]
        ]);
      });

      test('should resolve a Type', () {
        i = new Injector.slowReflective([ExampleService]);
        expect(i.get(ExampleService), const isInstanceOf<ExampleService>());
      });

      test('should resolve a Provider', () {
        i = new Injector.slowReflective([
          new Provider(ExampleService),
        ]);
        expect(i.get(ExampleService), const isInstanceOf<ExampleService>());
      });

      test('should resolve a Provider.useClass', () {
        i = new Injector.slowReflective([
          new Provider(ExampleService, useClass: ExampleService2),
        ]);
        expect(i.get(ExampleService), const isInstanceOf<ExampleService2>());
      });

      test('should resolve a Provider.useValue', () {
        final serviceValue = new ExampleService();
        i = new Injector.slowReflective([
          new Provider(ExampleService, useValue: serviceValue),
        ]);
        expect(i.get(ExampleService), serviceValue);
      });

      test('should resolve a Provider.useFactory', () {
        i = new Injector.slowReflective([
          new Provider(ExampleService, useFactory: createExampleService),
        ]);
        expect(i.get(ExampleService), const isInstanceOf<ExampleService>());
      });

      test('should resolve a Provider.useFactory with deps', () {
        i = new Injector.slowReflective([
          new Provider(String, useValue: 'Hello World'),
          new Provider(List, useFactory: createListWith),
        ]);
        expect(i.get(List), ['Hello World']);
      });

      test('should resolve a Provider.useFactory with manual deps', () {
        i = new Injector.slowReflective([
          new Provider(#fooBar, useValue: 'Hello World'),
          new Provider(List, useFactory: createListWith, deps: [#fooBar]),
        ]);
        expect(i.get(List), ['Hello World']);
      });

      test('should resolve a Provider.useExisting', () {
        i = new Injector.slowReflective([
          new Provider(ExampleService2),
          new Provider(ExampleService, useExisting: ExampleService2),
        ]);
        expect(i.get(ExampleService), i.get(ExampleService2));
      });

      test('should resolve a multi binding', () {
        i = new Injector.slowReflective([
          new Provider(#fooBar, useValue: 1, multi: true),
          new Provider(#fooBar, useValue: 2, multi: true),
        ]);
        expect(i.get(#fooBar), [1, 2]);
      });

      test('should resolve @Optional', () {
        i = new Injector.slowReflective([
          new Provider(List, useFactory: createListWithOptional),
        ]);
        expect(i.get(List), [null]);
      });

      test('should inject things in order of most-recently added', () {
        i = new Injector.slowReflective([
          new Provider(#a, useValue: 1),
          new Provider(#a, useValue: 2),
        ]);
        expect(i.get(#a), 2);
      });

      test('should return itself for "Injector"', () {
        i = new Injector.slowReflective([
          new Provider(#theInjector, useFactory: (i) => [i], deps: [Injector]),
        ]);
        expect(i.get(#theInjector), [i]);
      });

      test('should thrown when a provider was not found', () {
        i = new Injector.slowReflective([]);
        expect(() => i.get(#ABC), throwsArgumentError);
      });

      test('should support resolveAndCreateChild', () {
        final oldC = new C('oldC');
        final parent = ReflectiveInjector.resolveAndCreate([
          A,
          B,
          new Provider(C, useValue: oldC),
        ]);
        final newC = new C('newC');
        final child1 = parent.resolveAndCreateChild([
          B,
          new Provider(C, useValue: newC),
        ]);
        final newB = child1.get(B);
        expect(newB.c, newC, reason: 'Expected a new "C" binding');
        final child2 = child1.resolveAndCreateChild([
          new Provider(B, useValue: newB),
        ]);
        final newA = child2.get(A);
        expect(newA.b, isNot(newB), reason: 'Expected an old "B" binding');
        expect(newA.b.c, oldC, reason: 'Expected an old "C" binding');
      });
    });
  });
}

/// Implementation of [Injector] that captures [lastToken] and [lastOrElse].
class CaptureInjectInjector extends Injector {
  Object lastToken;
  OrElseInject lastOrElse;

  @override
  T inject<T>({Object token, OrElseInject<T> orElse}) {
    lastToken = token;
    lastOrElse = orElse;
    return null;
  }
}

class ExampleService {}

class ExampleService2 implements ExampleService {}

ExampleService createExampleService() => new ExampleService();
List createListWith(String item) => [item];

@Injectable()
List createListWithOptional(@Optional() String missing) => [missing];

@Injectable()
class A {
  final B b;
  A(this.b);
}

@Injectable()
class B {
  final C c;
  B(this.c);
}

@Injectable()
class C {
  final String debugMessage;

  C(this.debugMessage);

  @override
  String toString() => 'C: $debugMessage';
}
