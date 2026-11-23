import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports reactive Kortex primitives created inside `build` or `buildPage`,
/// where they would be recreated on every widget rebuild.
class AvoidKortexSignalInBuild extends AnalysisRule {
  /// Lint code reported when a reactive primitive is created in `build`.
  static const LintCode code = LintCode(
    'avoid_kortex_signal_in_build',
    "Avoid creating '{0}' inside build(); it will be recreated on every rebuild.",
    correctionMessage: 'Move reactive state into an IKortexController provided by KortexScope.',
  );

  /// Creates the rule instance.
  AvoidKortexSignalInBuild()
    : super(
        name: 'avoid_kortex_signal_in_build',
        description: 'Warn when reactive Kortex primitives are created inside widget build methods.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final name = node.name.lexeme;
    if (name != 'build' && name != 'buildPage') return;
    node.body.accept(_BodyVisitor(rule));
  }
}

class _BodyVisitor extends RecursiveAstVisitor<void> {
  _BodyVisitor(this.rule);

  final AnalysisRule rule;

  static const _reactiveConstructors = <String>{
    'KortexSignal',
    'Kortex',
    'KortexComputed',
    'KortexEffect',
    'KortexResource',
    'KortexStreamResource',
    'KortexCommand',
    'KortexList',
    'KortexMap',
    'KortexSet',
    'kortexSignal',
    'kortexComputed',
    'kortexEffect',
    'kortexResource',
    'kortexStreamResource',
    'kortexCommand',
    'kortexList',
    'kortexMap',
    'kortexSet',
  };

  static const _reactiveExtensions = <String>{
    'kortex',
    'kortexList',
    'kortexMap',
    'kortexSet',
  };

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (_reactiveConstructors.contains(name)) {
      rule.reportAtNode(node, arguments: [name]);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final name = node.propertyName.name;
    if (_reactiveExtensions.contains(name)) {
      rule.reportAtNode(node, arguments: ['.$name']);
    }
    super.visitPropertyAccess(node);
  }
}
