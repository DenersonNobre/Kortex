import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports signal mutations (`.value = ...`) inside `KortexComputed` callbacks.
class AvoidKortexSideEffectInComputed extends AnalysisRule {
  /// Lint code reported when a `KortexComputed` callback mutates `.value`.
  static const LintCode code = LintCode(
    'avoid_kortex_side_effect_in_computed',
    'Avoid mutating reactive state inside KortexComputed.',
    correctionMessage: 'Keep KortexComputed pure (read-only) and move side effects to KortexEffect or a controller method.',
  );

  /// Creates the rule instance.
  AvoidKortexSideEffectInComputed()
    : super(
        name: 'avoid_kortex_side_effect_in_computed',
        description: 'Warn when a KortexComputed callback mutates `.value` instead of staying pure.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addInstanceCreationExpression(this, _Visitor(this));
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final typeName = node.constructorName.type.name.lexeme;
    if (typeName != 'KortexComputed') return;
    _checkArguments(node.argumentList);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'kortexComputed') return;
    _checkArguments(node.argumentList);
  }

  void _checkArguments(ArgumentList argumentList) {
    for (final arg in argumentList.arguments) {
      if (arg is FunctionExpression) {
        arg.body.accept(_MutationVisitor(rule));
      }
    }
  }
}

class _MutationVisitor extends RecursiveAstVisitor<void> {
  _MutationVisitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final left = node.leftHandSide;
    if (left is PropertyAccess && left.propertyName.name == 'value') {
      rule.reportAtNode(node);
    } else if (left is PrefixedIdentifier && left.identifier.name == 'value') {
      rule.reportAtNode(node);
    }
    super.visitAssignmentExpression(node);
  }
}
