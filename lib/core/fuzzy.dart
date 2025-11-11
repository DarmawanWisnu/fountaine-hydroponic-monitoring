import 'dart:math' as math;

/// --- Core Fuzzy Types ---
abstract class MembershipFunction {
  double mu(double x);
}

class TriangularMF implements MembershipFunction {
  final double a, b, c; // a < b < c
  const TriangularMF(this.a, this.b, this.c);
  @override
  double mu(double x) {
    if (x <= a || x >= c) return 0.0;
    if (x == b) return 1.0;
    if (x > a && x < b) return (x - a) / (b - a);
    return (c - x) / (c - b);
  }
}

class TrapezoidalMF implements MembershipFunction {
  final double a, b, c, d; // a <= b <= c <= d
  const TrapezoidalMF(this.a, this.b, this.c, this.d);
  @override
  double mu(double x) {
    if (x <= a || x >= d) return 0.0;
    if (x >= b && x <= c) return 1.0;
    if (x > a && x < b) return (x - a) / (b - a);
    return (d - x) / (d - c);
  }
}

class FuzzyVariable {
  final String name;
  final double minX;
  final double maxX;
  final Map<String, MembershipFunction> terms; // e.g., {'low': MF, 'ideal': MF}

  const FuzzyVariable({
    required this.name,
    required this.minX,
    required this.maxX,
    required this.terms,
  });
}

class Clause {
  final String variable; // input variable name
  final String term; // term name within that variable
  const Clause(this.variable, this.term);
}

enum Connective { and, or }

class Antecedent {
  final List<Clause> clauses;
  final Connective connective; // combine clauses via min (AND) / max (OR)
  const Antecedent(this.clauses, {this.connective = Connective.and});

  double evaluate(
    Map<String, double> crispInputs,
    Map<String, FuzzyVariable> vars,
  ) {
    double? agg;
    for (final c in clauses) {
      final v = vars[c.variable]!;
      final mf = v.terms[c.term]!;
      final x = crispInputs[c.variable]!;
      final m = mf.mu(x);
      if (agg == null) {
        agg = m;
      } else {
        if (connective == Connective.and) {
          agg = math.min(agg, m);
        } else {
          agg = math.max(agg, m);
        }
      }
    }
    return agg ?? 0.0;
  }
}

class Consequent {
  final String variable; // output variable name
  final String term; // term name of output variable
  const Consequent(this.variable, this.term);
}

class FuzzyRule {
  final String name;
  final Antecedent ifPart;
  final List<Consequent> thenParts; // allow multiple consequents
  final double weight; // [0,1], default 1.0
  const FuzzyRule({
    required this.name,
    required this.ifPart,
    required this.thenParts,
    this.weight = 1.0,
  });
}

class FuzzyEngine {
  final Map<String, FuzzyVariable> inputs;
  final Map<String, FuzzyVariable> outputs;
  final List<FuzzyRule> rules;

  const FuzzyEngine({
    required this.inputs,
    required this.outputs,
    required this.rules,
  });

  /// Evaluate crisp inputs → defuzzified outputs.
  /// samplingSteps: number of points for centroid discretization.
  Map<String, double> evaluate(
    Map<String, double> crispInputs, {
    int samplingSteps = 201,
  }) {
    // 1) For each output var, build aggregated membership (y) via max of clipped consequents
    final Map<String, List<double>> xs = {};
    final Map<String, List<double>> mus = {};

    outputs.forEach((name, v) {
      xs[name] = _linspace(v.minX, v.maxX, samplingSteps);
      mus[name] = List<double>.filled(samplingSteps, 0.0);
    });

    for (final rule in rules) {
      final fireStrength =
          rule.ifPart.evaluate(crispInputs, inputs) * rule.weight;
      if (fireStrength <= 0) continue;
      for (final cons in rule.thenParts) {
        final outVar = outputs[cons.variable]!;
        final outMF = outVar.terms[cons.term]!;
        final xList = xs[cons.variable]!;
        final yList = mus[cons.variable]!;
        for (int i = 0; i < xList.length; i++) {
          final y = outMF.mu(xList[i]);
          // Clip by fire strength (Mamdani implication)
          final clipped = math.min(y, fireStrength);
          yList[i] = math.max(yList[i], clipped); // aggregate via max
        }
      }
    }

    // 2) Defuzzify each output via centroid
    final Map<String, double> result = {};
    outputs.forEach((name, v) {
      final x = xs[name]!;
      final y = mus[name]!;
      final num = _dot(x, y);
      final den = y.fold<double>(0.0, (a, b) => a + b);
      result[name] = den == 0 ? (v.minX + v.maxX) / 2.0 : (num / den);
    });

    return result;
  }

  // Helpers
  static List<double> _linspace(double start, double end, int steps) {
    if (steps <= 1) return [start];
    final step = (end - start) / (steps - 1);
    return List<double>.generate(steps, (i) => start + i * step);
  }

  static double _dot(List<double> a, List<double> b) {
    double s = 0.0;
    for (int i = 0; i < a.length; i++) {
      s += a[i] * b[i];
    }
    return s;
  }
}

/// --- Domain-Specific Setup (Hydroponic pH & EC → dosing_level) ---
class HydroFuzzyFactory {
  // Input: pH (4.0–8.0)
  static FuzzyVariable pHVar() => FuzzyVariable(
    name: 'pH',
    minX: 4.0,
    maxX: 8.0,
    terms: const {
      'low': TrapezoidalMF(4.0, 4.0, 5.5, 6.0),
      'ideal': TriangularMF(5.7, 6.4, 6.9),
      'high': TrapezoidalMF(6.7, 7.3, 8.0, 8.0),
    },
  );

  // Input: EC (mS/cm) (0.5–3.0)
  static FuzzyVariable ecVar() => FuzzyVariable(
    name: 'EC',
    minX: 0.5,
    maxX: 3.0,
    terms: const {
      'weak': TrapezoidalMF(0.5, 0.5, 1.0, 1.4),
      'ideal': TriangularMF(1.2, 1.8, 2.2),
      'strong': TrapezoidalMF(2.0, 2.4, 3.0, 3.0),
    },
  );

  // Output: dosing_level (0–100)
  static FuzzyVariable dosingVar() => FuzzyVariable(
    name: 'dosing_level',
    minX: 0.0,
    maxX: 100.0,
    terms: const {
      'none': TrapezoidalMF(0, 0, 10, 20),
      'small': TriangularMF(15, 30, 45),
      'medium': TriangularMF(40, 60, 75),
      'large': TrapezoidalMF(70, 85, 100, 100),
    },
  );

  static List<FuzzyRule> rules() => [
    FuzzyRule(
      name: 'R1',
      ifPart: Antecedent([Clause('pH', 'low'), Clause('EC', 'weak')]),
      thenParts: [Consequent('dosing_level', 'medium')],
    ),
    FuzzyRule(
      name: 'R2',
      ifPart: Antecedent([Clause('pH', 'low'), Clause('EC', 'ideal')]),
      thenParts: [Consequent('dosing_level', 'small')],
    ),
    FuzzyRule(
      name: 'R3',
      ifPart: Antecedent([Clause('pH', 'low'), Clause('EC', 'strong')]),
      thenParts: [Consequent('dosing_level', 'none')],
    ),
    FuzzyRule(
      name: 'R4',
      ifPart: Antecedent([Clause('pH', 'ideal'), Clause('EC', 'weak')]),
      thenParts: [Consequent('dosing_level', 'small')],
    ),
    FuzzyRule(
      name: 'R5',
      ifPart: Antecedent([Clause('pH', 'ideal'), Clause('EC', 'ideal')]),
      thenParts: [Consequent('dosing_level', 'none')],
    ),
    FuzzyRule(
      name: 'R6',
      ifPart: Antecedent([Clause('pH', 'ideal'), Clause('EC', 'strong')]),
      thenParts: [Consequent('dosing_level', 'none')],
    ),
    FuzzyRule(
      name: 'R7',
      ifPart: Antecedent([Clause('pH', 'high'), Clause('EC', 'weak')]),
      thenParts: [Consequent('dosing_level', 'small')],
    ),
    FuzzyRule(
      name: 'R8',
      ifPart: Antecedent([Clause('pH', 'high'), Clause('EC', 'ideal')]),
      thenParts: [Consequent('dosing_level', 'none')],
    ),
    FuzzyRule(
      name: 'R9',
      ifPart: Antecedent([Clause('pH', 'high'), Clause('EC', 'strong')]),
      thenParts: [Consequent('dosing_level', 'none')],
    ),
  ];

  static FuzzyEngine buildEngine() => FuzzyEngine(
    inputs: {'pH': pHVar(), 'EC': ecVar()},
    outputs: {'dosing_level': dosingVar()},
    rules: rules(),
  );
}

/// Convenience wrapper for your app: evaluate and derive alert/risk.
class FuzzyResult {
  final double dosingLevel; // 0..100
  final double riskScore; // 0..1 (heuristic)
  final String alertLevel; // 'normal' | 'warning' | 'critical'
  final Map<String, double> debugMembership; // optional for UI/debug
  const FuzzyResult({
    required this.dosingLevel,
    required this.riskScore,
    required this.alertLevel,
    this.debugMembership = const {},
  });
}

class HydroFuzzyService {
  HydroFuzzyService({FuzzyEngine? engine})
    : _engine = engine ?? HydroFuzzyFactory.buildEngine();
  final FuzzyEngine _engine;

  FuzzyResult evaluate({required double pH, required double ec}) {
    final out = _engine.evaluate({'pH': pH, 'EC': ec});
    final dosing = out['dosing_level']!.clamp(0.0, 100.0);

    // Simple risk heuristic: distance from ideal windows
    double pHDeviation = 0.0;
    if (pH < 5.7) pHDeviation = (5.7 - pH) / 1.7; // normalize to ~[0,1]
    if (pH > 6.9) pHDeviation = (pH - 6.9) / 1.1;
    final ecDeviation = ec < 1.2
        ? (1.2 - ec) / 0.7
        : (ec > 2.2 ? (ec - 2.2) / 0.8 : 0.0);
    final risk = (pHDeviation + ecDeviation) / 2.0;
    final riskClamped = risk.clamp(0.0, 1.0);
    final alert = riskClamped < 0.33
        ? 'normal'
        : (riskClamped < 0.66 ? 'warning' : 'critical');

    return FuzzyResult(
      dosingLevel: dosing,
      riskScore: riskClamped,
      alertLevel: alert,
      debugMembership: out,
    );
  }
}
