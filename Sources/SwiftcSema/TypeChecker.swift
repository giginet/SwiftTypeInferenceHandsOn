import SwiftcBasic
import SwiftcType
import SwiftcAST

public final class TypeChecker {
    private let source: SourceFile
    
    public init(source: SourceFile) {
        self.source = source
    }
    
    public func typeCheck() throws {
        for index in 0..<source.statements.count {
            source.statements[index] = try typeCheckStatement(source.statements[index],
                                                              context: source)
        }
    }
    
    public func typeCheckStatement(_ stmt: ASTNode,
                                   context: DeclContext) throws -> ASTNode {
        switch stmt {
        case let vd as VariableDecl:
            if let ie = vd.initializer {
                vd.initializer = try typeCheckExpr(ie,
                                                   context: vd)
            }
        case let ex as Expr:
            return try typeCheckExpr(ex,
                                     context: context)
        default:
            break
        }
        return stmt
    }
    
    public func typeCheckExpr(_ expr: Expr,
                              context: DeclContext) throws -> Expr {
        var expr = try preCheckExpr(expr,
                                    context: context)
        
        let cts = ConstraintSystem()
        try cts.generateConstraints(expr: expr,
                                   context: context)
        let solutions = cts.solve()
        guard let solution = solutions.first else {
            throw MessageError("no solution")
        }
        expr = try (solution.apply(to: expr, context: context,
                                   constraintSystem: cts) as! Expr)
        return expr
    }
    
    private func preCheckExpr(_ expr: Expr,
                              context: DeclContext) throws -> Expr {
        let expr = try resolveDeclRef(expr: expr,
                                      context: context)
        return expr
    }
    
    private func resolveDeclRef(expr: Expr,
                                context: DeclContext) throws -> Expr {
        func tr(node: ASTNode, context: DeclContext) throws -> ASTNode? {
            switch node {
            case let node as UnresolvedDeclRefExpr:
                let name = node.name
                
                let targets = context.resolve(name: name)
                guard targets.count > 0 else {
                    throw MessageError("failed to resolve: \(name)")
                }
                
                if targets.count == 1 {
                    return DeclRefExpr(source: source, sourceRange: node.sourceRange,
                                       name: name, target: targets[0])
                } else {
                    return OverloadedDeclRefExpr(source: source, sourceRange: node.sourceRange,
                                                 name: name, targets: targets)
                }
            default:
                return nil
            }
        }
        
        return try expr.transform(context: context, tr) as! Expr
    }
}
