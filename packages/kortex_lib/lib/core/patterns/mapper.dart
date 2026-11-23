/// Mapeia um tipo fonte para um tipo alvo (ex.: Entity <-> Dto).
/// Atribuição: **PofEAA — Data Mapper (Fowler)**; fora dos 23 GoF.
///
abstract interface class IMapper<TSource, TTarget> {
  TTarget map(TSource source);
}

extension MapperSourceX<TSource, TTarget> on TSource {
  TTarget toMapped(IMapper<TSource, TTarget> mapper) => mapper.map(this);
}

extension MapperIterableX<TSource, TTarget> on Iterable<TSource> {
  List<TTarget> toMappedList(IMapper<TSource, TTarget> mapper) =>
      map(mapper.map).toList();
}
