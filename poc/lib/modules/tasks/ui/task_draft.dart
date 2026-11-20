/// Rascunho mutavel do formulario de task.
///
/// Fonte da verdade da edicao sem `TextEditingController`: os campos do
/// `Form` escrevem aqui via `onChanged` e o submit le daqui. Limpar o
/// formulario e [clear].
class TaskDraft {
  String title = '';
  int? categoryId;

  void clear() {
    title = '';
    categoryId = null;
  }
}
