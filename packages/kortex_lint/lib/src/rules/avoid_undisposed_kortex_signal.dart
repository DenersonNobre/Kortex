import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports reactive Kortex primitives declared in an `IKortexController`
/// without being registered via `autoDispose(...)` or `disposeBag.add(...)`.
class AvoidUndisposedKortexSignal extends AnalysisRule {
  /// Lint code reported when a reactive field is not registered for disposal.
  static const LintCode code = LintCode(
    'avoid_undisposed_kortex_signal',
    "Reactive primitive '{0}' is not registered with autoDispose() or disposeBag.add().",
    correctionMessage: 'Register it in the constructor with autoDispose({0}) to prevent memory leaks.',
  );

  /// Creates the rule instance.
  AvoidUndisposedKortexSignal()
    : super(
        name: 'avoid_undisposed_kortex_signal',
        description: 'Warn when reactive Kortex fields in IKortexController are not registered for disposal.',
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

  static const _reactiveTypes = <String>{
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
  };

  static const _reactiveExtensions = <String>{
    'kortex',
    'kortexList',
    'kortexMap',
    'kortexSet',
  };

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!_extendsOrImplementsController(node)) return;

    final disposedNames = _collectDisposedIdentifiers(node);

    for (final member in node.body.members) {
      if (member is! FieldDeclaration || member.isStatic) continue;
      final fields = member.fields;
      final explicitType = _baseTypeName(fields.type);

      for (final variable in fields.variables) {
        final name = variable.name.lexeme;
        if (!_isReactiveField(explicitType, variable.initializer)) continue;
        if (disposedNames.contains(name)) continue;
        rule.reportAtToken(variable.name, arguments: [name]);
      }
    }
  }

  bool _extendsOrImplementsController(ClassDeclaration node) {
    final superclass = node.extendsClause?.superclass.name.lexeme;
    if (superclass == 'IKortexController') return true;
    final interfaces = node.implementsClause?.interfaces;
    if (interfaces == null) return false;
    return interfaces.any((i) => i.name.lexeme == 'IKortexController');
  }

  String? _baseTypeName(TypeAnnotation? type) {
    if (type is NamedType) return type.name.lexeme;
    return null;
  }

  bool _isReactiveField(String? explicitType, Expression? initializer) {
    if (explicitType != null && _reactiveTypes.contains(explicitType)) {
      return true;
    }
    if (initializer is MethodInvocation) {
      final methodName = initializer.methodName.name;
      if (_reactiveTypes.contains(methodName) ||
          methodName.startsWith('kortex')) {
        return true;
      }
    }
    if (initializer is PropertyAccess &&
        _reactiveExtensions.contains(initializer.propertyName.name)) {
      return true;
    }
    if (initializer is PrefixedIdentifier &&
        _reactiveExtensions.contains(initializer.identifier.name)) {
      return true;
    }
    return false;
  }

  Set<String> _collectDisposedIdentifiers(ClassDeclaration node) {
    final collector = _DisposedCollector();
    node.body.accept(collector);
    return collector.names;
  }
}

class _DisposedCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final method = node.methodName.name;
    if ((method == 'autoDispose' || method == 'add') &&
        node.argumentList.arguments.isNotEmpty) {
      final first = node.argumentList.arguments.first;
      if (first is SimpleIdentifier) {
        names.add(first.name);
      }
    } else if (method == 'dispose') {
      final target = node.target;
      if (target is SimpleIdentifier) {
        names.add(target.name);
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final rhs = node.rightHandSide;
    if (rhs is MethodInvocation && rhs.methodName.name == 'autoDispose') {
      final lhs = node.leftHandSide;
      if (lhs is SimpleIdentifier) {
        names.add(lhs.name);
      }
    }
    super.visitAssignmentExpression(node);
  }
}
