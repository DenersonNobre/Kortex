import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports public `abstract`, `sealed`, or `interface` classes whose name
/// does not start with `I` (e.g. `IKortexController`, `IResult`).
class PreferIPrefixForAbstractions extends AnalysisRule {
  /// Lint code reported when an abstraction misses the `I` prefix.
  static const LintCode code = LintCode(
    'prefer_i_prefix_for_abstractions',
    "Public abstraction '{0}' should start with the 'I' prefix.",
    correctionMessage: "Rename '{0}' to 'I{0}'.",
  );

  /// Creates the rule instance.
  PreferIPrefixForAbstractions()
    : super(
        name: 'prefer_i_prefix_for_abstractions',
        description: 'Enforce the I- prefix on public abstract, sealed, and interface classes.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final isAbstraction =
        node.abstractKeyword != null ||
        node.sealedKeyword != null ||
        node.interfaceKeyword != null;
    if (!isAbstraction) return;

    final token = node.namePart.typeName;
    final name = token.lexeme;
    if (name.startsWith('_')) return;

    final hasPrefix =
        name.length >= 2 &&
        name.startsWith('I') &&
        name[1] == name[1].toUpperCase();
    if (!hasPrefix) {
      rule.reportAtToken(token, arguments: [name]);
    }
  }
}
