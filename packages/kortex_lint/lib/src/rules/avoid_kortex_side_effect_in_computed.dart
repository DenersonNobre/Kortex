import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports signal mutations (`.value = ...`, `++`/`--`, mutating collection
/// methods) inside `KortexComputed` callbacks.
class AvoidKortexSideEffectInComputed extends AnalysisRule {
  /// Lint code reported when a `KortexComputed` callback mutates reactive state.
  static const LintCode code = LintCode(
    'avoid_kortex_side_effect_in_computed',
    'Avoid mutating reactive state inside KortexComputed.',
    correctionMessage: 'Keep KortexComputed pure (read-only) and move side effects to KortexEffect or a controller method.',
  );

  /// Creates the rule instance.
  AvoidKortexSideEffectInComputed()
    : super(
        name: 'avoid_kortex_side_effect_in_computed',
        description: 'Warn when a KortexComputed callback mutates reactive state instead of staying pure.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _ComputedVisitor(onViolation: reportAtNode);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }

  /// Collects all side-effect AST nodes inside `KortexComputed` / `kortexComputed`
  /// in [unit] (used by unit tests to exercise the rule directly).
  static List<AstNode> findViolations(CompilationUnit unit) {
    final violations = <AstNode>[];
    unit.accept(_UnitCollector(violations.add));
    return violations;
  }
}

class _UnitCollector extends RecursiveAstVisitor<void> {
  _UnitCollector(this.onViolation);

  final void Function(AstNode node) onViolation;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _ComputedVisitor(onViolation: onViolation)
        .visitInstanceCreationExpression(node);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _ComputedVisitor(onViolation: onViolation).visitMethodInvocation(node);
    super.visitMethodInvocation(node);
  }
}

class _ComputedVisitor extends SimpleAstVisitor<void> {
  _ComputedVisitor({required this.onViolation});

  final void Function(AstNode node) onViolation;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final typeName = node.constructorName.type.name.lexeme;
    if (typeName != 'KortexComputed') return;
    _checkArguments(node.argumentList);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (name != 'kortexComputed' && name != 'KortexComputed') return;
    _checkArguments(node.argumentList);
  }

  void _checkArguments(ArgumentList argumentList) {
    for (final arg in argumentList.arguments) {
      if (arg is FunctionExpression) {
        arg.body.accept(_MutationVisitor(onViolation));
      }
    }
  }
}

class _MutationVisitor extends RecursiveAstVisitor<void> {
  _MutationVisitor(this.onViolation);

  final void Function(AstNode node) onViolation;

  static const _mutatingMethods = <String>{
    'add',
    'addAll',
    'clear',
    'insert',
    'insertAll',
    'putIfAbsent',
    'remove',
    'removeAt',
    'removeWhere',
    'sort',
  };

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Do not descend into nested closures returned or passed as callbacks.
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (_isValueTarget(node.leftHandSide)) {
      onViolation(node);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (_isIncrementOrDecrement(node.operator.type) &&
        _isValueTarget(node.operand)) {
      onViolation(node);
    }
    super.visitPrefixExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (_isIncrementOrDecrement(node.operator.type) &&
        _isValueTarget(node.operand)) {
      onViolation(node);
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_mutatingMethods.contains(node.methodName.name)) {
      onViolation(node);
    }
    super.visitMethodInvocation(node);
  }

  static bool _isIncrementOrDecrement(TokenType type) =>
      type == TokenType.PLUS_PLUS || type == TokenType.MINUS_MINUS;

  static bool _isValueTarget(Expression expr) =>
      (expr is PropertyAccess && expr.propertyName.name == 'value') ||
      (expr is PrefixedIdentifier && expr.identifier.name == 'value');
}
