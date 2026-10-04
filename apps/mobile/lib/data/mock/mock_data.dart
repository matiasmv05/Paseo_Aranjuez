/// Modelos y datos de prueba desacoplados para la visualización del frontend.
///
/// Cumplen con la especificación de diseño oficial de Paseo Points.
library;

/// Representación del usuario cliente para demostración de interfaz.
class MockUser {
  /// Crea una instancia del usuario mock.
  const new({
    required this.name,
    required this.email,
    required this.phone,
    required this.balance,
    required this.avatarAsset,
    required this.qrCodePayload,
  });

  /// Nombre completo del usuario.
  final String name;

  /// Dirección de correo electrónico.
  final String email;

  /// Número de teléfono en formato E.164.
  final String phone;

  /// Saldo actual de puntos acumulados.
  final int balance;

  /// Ruta al archivo de imagen de avatar del perfil.
  final String avatarAsset;

  /// Carga de datos que codifica el código QR.
  final String qrCodePayload;
}

/// Representa un beneficio o recompensa del catálogo.
class MockBenefit {
  /// Crea una instancia de beneficio mock.
  const new({
    required this.id,
    required this.title,
    required this.establishment,
    required this.category,
    required this.pointsRequired,
    required this.imageAsset,
    required this.description,
    required this.conditions,
  });

  /// Identificador único del beneficio.
  final String id;

  /// Título visible de la recompensa.
  final String title;

  /// Nombre del establecimiento oferente.
  final String establishment;

  /// Categoría del beneficio (Gastronomía, Moda, etc.).
  final String category;

  /// Puntos necesarios para realizar el canje.
  final int pointsRequired;

  /// Ruta de la imagen del beneficio.
  final String imageAsset;

  /// Descripción detallada del beneficio.
  final String description;

  /// Lista de condiciones y restricciones.
  final List<String> conditions;
}

/// Representa un comercio participante del centro comercial Paseo Aranjuez.
class MockEstablishment {
  /// Crea una instancia de comercio mock.
  const new({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.hours,
    required this.imageAsset,
    required this.activePromotionsCount,
  });

  /// Identificador único del establecimiento.
  final String id;

  /// Nombre comercial del establecimiento.
  final String name;

  /// Categoría del local comercial.
  final String category;

  /// Ubicación física dentro del centro comercial.
  final String location;

  /// Horario de atención al público.
  final String hours;

  /// Imagen de cabecera o logotipo del comercio.
  final String imageAsset;

  /// Cantidad de promociones vigentes.
  final int activePromotionsCount;
}

/// Tipo de movimiento en el ledger de puntos.
enum TransactionType {
  /// Puntos ganados por compras.
  earned,

  /// Puntos canjeados en beneficios.
  spent,
}

/// Representa un movimiento histórico en la cuenta de puntos del cliente.
class MockTransaction {
  /// Crea una transacción mock.
  const new({
    required this.id,
    required this.date,
    required this.establishment,
    required this.points,
    required this.type,
    required this.status,
  });

  /// Identificador del registro del movimiento.
  final String id;

  /// Fecha formateada del movimiento.
  final String date;

  /// Descripción o nombre del establecimiento.
  final String establishment;

  /// Cantidad de puntos (positivo o negativo).
  final int points;

  /// Tipo de movimiento (ganado o canjeado).
  final TransactionType type;

  /// Etiqueta visible del estado del movimiento.
  final String status;
}

/// Representa una promoción vigente en Paseo Aranjuez.
class MockPromotion {
  /// Crea una promoción mock.
  const new({
    required this.id,
    required this.title,
    required this.badge,
    required this.description,
    required this.imageAsset,
    required this.validUntil,
  });

  /// Identificador de la promoción.
  final String id;

  /// Título de la promoción.
  final String title;

  /// Etiqueta destacada (ej. "Promoción").
  final String badge;

  /// Descripción detallada de la oferta.
  final String description;

  /// Imagen de la promoción.
  final String imageAsset;

  /// Período de vigencia.
  final String validUntil;
}

/// Repositorio de datos locales estáticos para la interfaz de Paseo Points.
abstract final class MockData {
  /// Usuario actual de demostración.
  static const MockUser currentUser = MockUser(
    name: 'Valentina Rodríguez',
    email: 'valentina@email.com',
    phone: '+591 720 12345',
    balance: 2450,
    avatarAsset: 'assets/images/valentina_avatar.jpg',
    qrCodePayload: 'PASEO-POINTS:VALENTINA-RODRIGUEZ:ARJ-72012345',
  );

  /// Lista de beneficios del catálogo.
  static const List<MockBenefit> benefits = [
    MockBenefit(
      id: 'ben-01',
      title: '20% de descuento en Café Aranjuez',
      establishment: 'Café Aranjuez',
      category: 'Gastronomía',
      pointsRequired: 500,
      imageAsset: 'assets/images/cafe_cappuccino.jpg',
      description:
          'Disfruta de un 20% de descuento en todo el menú de Café Aranjuez. '
          'Perfecto para compartir momentos especiales.',
      conditions: [
        'Válido en sucursales del Paseo Aranjuez',
        'No acumulable con otras promociones',
        'Válido hasta el 31 de diciembre de 2025',
      ],
    ),
    MockBenefit(
      id: 'ben-02',
      title: 'Descuento en nueva colección',
      establishment: 'ZARA',
      category: 'Moda',
      pointsRequired: 800,
      imageAsset: 'assets/images/zara_fashion.jpg',
      description:
          'Aprovecha un beneficio exclusivo del 15% en prendas seleccionadas '
          'de la colección de temporada.',
      conditions: [
        'Aplica exclusivamente en tienda Paseo Aranjuez',
        'Presentar cupón QR antes del cobro en caja',
        'Válido hasta agotar existencias',
      ],
    ),
    MockBenefit(
      id: 'ben-03',
      title: 'Postre gratis',
      establishment: 'El Cuarto',
      category: 'Gastronomía',
      pointsRequired: 350,
      imageAsset: 'assets/images/el_cuarto_dessert.jpg',
      description:
          'Recibe un postre artesanal de cortesía por consumos superiores '
          'a 120 Bs en tu visita a El Cuarto.',
      conditions: [
        'Sujeto a disponibilidad del menú del día',
        'Válido de lunes a jueves en horario regular',
      ],
    ),
    MockBenefit(
      id: 'ben-04',
      title: 'Combo especial',
      establishment: 'Sky Games',
      category: 'Entretenimiento',
      pointsRequired: 700,
      imageAsset: 'assets/images/sky_games_arcade.jpg',
      description:
          'Pase de 2 horas ilimitadas en máquinas arcade y simuladores '
          'para toda la familia.',
      conditions: [
        'No incluye máquinas de premios directos',
        'Un solo pase por miembro al día',
      ],
    ),
  ];

  /// Lista de comercios participantes.
  static const List<MockEstablishment> establishments = [
    MockEstablishment(
      id: 'est-01',
      name: 'Café Aranjuez',
      category: 'Gastronomía',
      location: 'Piso 1 • Local 12',
      hours: '9:00 - 22:00',
      imageAsset: 'assets/images/cafe_cappuccino.jpg',
      activePromotionsCount: 2,
    ),
    MockEstablishment(
      id: 'est-02',
      name: 'ZARA',
      category: 'Ropa',
      location: 'Piso 2 • Local 34',
      hours: '10:00 - 21:00',
      imageAsset: 'assets/images/zara_fashion.jpg',
      activePromotionsCount: 1,
    ),
    MockEstablishment(
      id: 'est-03',
      name: 'Sky Games',
      category: 'Entretenimiento',
      location: 'Piso 3 • Local 18',
      hours: '11:00 - 23:00',
      imageAsset: 'assets/images/sky_games_arcade.jpg',
      activePromotionsCount: 1,
    ),
    MockEstablishment(
      id: 'est-04',
      name: 'El Cuarto',
      category: 'Gastronomía',
      location: 'Piso 1 • Local 07',
      hours: '12:00 - 23:00',
      imageAsset: 'assets/images/el_cuarto_dessert.jpg',
      activePromotionsCount: 2,
    ),
  ];

  /// Lista de transacciones del historial de puntos.
  static const List<MockTransaction> transactions = [
    MockTransaction(
      id: 'tx-01',
      date: '03 Oct 2025',
      establishment: 'Compra en Café Aranjuez',
      points: 120,
      type: TransactionType.earned,
      status: 'Ganados',
    ),
    MockTransaction(
      id: 'tx-02',
      date: '01 Oct 2025',
      establishment: 'Compra en ZARA',
      points: 85,
      type: TransactionType.earned,
      status: 'Ganados',
    ),
    MockTransaction(
      id: 'tx-03',
      date: '28 Sep 2025',
      establishment: 'Canje de recompensa',
      points: -500,
      type: TransactionType.spent,
      status: 'Canjeados',
    ),
    MockTransaction(
      id: 'tx-04',
      date: '25 Sep 2025',
      establishment: 'Compra en Sky Games',
      points: 100,
      type: TransactionType.earned,
      status: 'Ganados',
    ),
  ];

  /// Lista de promociones activas.
  static const List<MockPromotion> promotions = [
    MockPromotion(
      id: 'prom-01',
      title: 'Puntos dobles este fin de semana',
      badge: 'Promoción',
      description:
          'Acumula el doble de puntos en todos los restaurantes y boutiques '
          'asociadas al pagar y presentar tu código QR.',
      imageAsset: 'assets/images/promocion_shopping.jpg',
      validUntil: 'Válido sábado y domingo',
    ),
  ];
}
