// [ISpecification] encapsula um predicado reutilizável, nomeável e componível
// sobre uma entidade: cada Concrete ISpecification decide se um candidato a
// satisfaz, sem vazar lógica de consulta para o domínio.
//
// Composição canônica: [and]/[or]/[not] (e operadores `&`/`|`) montam árvores
// booleanas com curto-circuito; [ISpecification.of] adapta um predicado; a
// FONTE DE DADOS traduz a spec para o mecanismo nativo (WHERE, query params)
// fora deste arquivo.
//
// Atribuição: padrão **ISpecification** — Martin Fowler, *Patterns of
// Enterprise Application Architecture* (2002); também central no DDD de Eric
// Evans (2003) — fora dos 23 GoF.

abstract class ISpecification<T> {
  const ISpecification._();

  /// `true` se [candidate] satisfaz esta especificação.
  bool isSatisfiedBy(T candidate);

  /// Ambas (curto-circuito à esquerda).
  ISpecification<T> and(ISpecification<T> other) =>
      AndSpecification<T>(this, other);

  /// Pelo menos uma.
  ISpecification<T> or(ISpecification<T> other) =>
      OrSpecification<T>(this, other);

  /// Negação.
  ISpecification<T> not() => NotSpecification<T>(this);

  /// Atalho sintático para [and].
  ISpecification<T> operator &(ISpecification<T> other) => and(other);

  /// Atalho sintático para [or].
  ISpecification<T> operator |(ISpecification<T> other) => or(other);

  /// Constrói uma spec a partir de um [predicate] arbitrário.
  factory ISpecification.of(bool Function(T candidate) predicate) =>
      _PredicateSpecification<T>(predicate);

  /// Spec universal: todo candidato satisfaz.
  factory ISpecification.all() => _AllSpecification<T>();

  /// Spec vazia: nenhum candidato satisfaz.
  factory ISpecification.none() => _NoneSpecification<T>();
}

/// Composição AND (GoF Composite).
class AndSpecification<T> extends ISpecification<T> {
  final ISpecification<T> left;
  final ISpecification<T> right;

  AndSpecification(this.left, this.right) : super._();

  @override
  bool isSatisfiedBy(T candidate) =>
      left.isSatisfiedBy(candidate) && right.isSatisfiedBy(candidate);
}

/// Composição OR (GoF Composite).
class OrSpecification<T> extends ISpecification<T> {
  final ISpecification<T> left;
  final ISpecification<T> right;

  OrSpecification(this.left, this.right) : super._();

  @override
  bool isSatisfiedBy(T candidate) =>
      left.isSatisfiedBy(candidate) || right.isSatisfiedBy(candidate);
}

/// Negação (GoF Composite/Decorator).
class NotSpecification<T> extends ISpecification<T> {
  final ISpecification<T> inner;

  NotSpecification(this.inner) : super._();

  @override
  bool isSatisfiedBy(T candidate) => !inner.isSatisfiedBy(candidate);
}

class _PredicateSpecification<T> extends ISpecification<T> {
  final bool Function(T candidate) _predicate;

  _PredicateSpecification(this._predicate) : super._();

  @override
  bool isSatisfiedBy(T candidate) => _predicate(candidate);
}

class _AllSpecification<T> extends ISpecification<T> {
  const _AllSpecification() : super._();

  @override
  bool isSatisfiedBy(T candidate) => true;
}

class _NoneSpecification<T> extends ISpecification<T> {
  const _NoneSpecification() : super._();

  @override
  bool isSatisfiedBy(T candidate) => false;
}
