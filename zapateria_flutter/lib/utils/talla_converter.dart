// Shoe size conversion — canonical system is MX (Mexican cm-based).
// Formulas confirmed by user: MX 24 = EU 38 = US 7 = CN 38
//   EU = MX + 14
//   CN = MX + 14  (CN follows EU for imported shoes in Mexico)
//   US = MX - 17

enum SistemaTalla { mx, eu, us, cn }

extension SistemaTallaLabel on SistemaTalla {
  String get label {
    switch (this) {
      case SistemaTalla.mx: return 'MX';
      case SistemaTalla.eu: return 'EU';
      case SistemaTalla.us: return 'US';
      case SistemaTalla.cn: return 'CN';
    }
  }
}

class TallaEquivalencia {
  final double mx;
  final double eu;
  final double us;
  final double cn;

  const TallaEquivalencia({
    required this.mx,
    required this.eu,
    required this.us,
    required this.cn,
  });
}

double mxToEu(double mx) => mx + 14;
double mxToUs(double mx) => mx - 17;
double mxToCn(double mx) => mx + 14;

double euToMx(double eu) => eu - 14;
double usToMx(double us) => us + 17;
double cnToMx(double cn) => cn - 14;

double toMx(SistemaTalla sistema, double value) {
  switch (sistema) {
    case SistemaTalla.mx: return value;
    case SistemaTalla.eu: return euToMx(value);
    case SistemaTalla.us: return usToMx(value);
    case SistemaTalla.cn: return cnToMx(value);
  }
}

TallaEquivalencia equivalencias(double mx) => TallaEquivalencia(
  mx: mx,
  eu: mxToEu(mx),
  us: mxToUs(mx),
  cn: mxToCn(mx),
);

String formatTalla(double t) =>
    t % 1 == 0 ? t.toInt().toString() : t.toString();

// Returns "MX 24 · EU 38 · US 7 · CN 38"
String tallaResumen(double mx) {
  final eq = equivalencias(mx);
  return 'MX ${formatTalla(eq.mx)} · EU ${formatTalla(eq.eu)} · US ${formatTalla(eq.us)} · CN ${formatTalla(eq.cn)}';
}
