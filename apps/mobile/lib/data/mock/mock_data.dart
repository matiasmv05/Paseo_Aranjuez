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

/// Estado de un cupón de canje de recompensa (HU-07, HU-12).
enum RedemptionStatus {
  /// Emitido y pendiente de canje en el establecimiento.
  issued,

  /// Consumido y entregado por el comercio.
  used,

  /// Expirado por tiempo transcurrido.
  expired,
}

/// Representa un cupón de canje de un solo uso generado por el cliente.
class MockRedemptionCoupon {
  /// Crea una instancia de cupón de canje.
  const new({
    required this.id,
    required this.code,
    required this.rewardId,
    required this.rewardTitle,
    required this.establishmentName,
    required this.customerName,
    required this.customerPhone,
    required this.pointsSpent,
    required this.status,
    required this.issuedAt,
    this.usedAt,
  });

  /// Identificador único del canje.
  final String id;

  /// Código único generado (ej. "PA-483921").
  final String code;

  /// ID del beneficio canjeado.
  final String rewardId;

  /// Título del beneficio canjeado.
  final String rewardTitle;

  /// Nombre del establecimiento oferente.
  final String establishmentName;

  /// Nombre del cliente titular.
  final String customerName;

  /// Teléfono del cliente.
  final String customerPhone;

  /// Cantidad de puntos deducidos.
  final int pointsSpent;

  /// Estado actual del cupón.
  final RedemptionStatus status;

  /// Fecha y hora de emisión.
  final String issuedAt;

  /// Fecha y hora en la que fue consumido en caja.
  final String? usedAt;

  /// Retorna una copia con el nuevo estado.
  MockRedemptionCoupon copyWith({RedemptionStatus? status, String? usedAt}) {
    return MockRedemptionCoupon(
      id: id,
      code: code,
      rewardId: rewardId,
      rewardTitle: rewardTitle,
      establishmentName: establishmentName,
      customerName: customerName,
      customerPhone: customerPhone,
      pointsSpent: pointsSpent,
      status: status ?? this.status,
      issuedAt: issuedAt,
      usedAt: usedAt ?? this.usedAt,
    );
  }
}

/// Nivel de lealtad dentro de la experiencia de gamificación (HU-22).
enum LoyaltyTier {
  /// Nivel inicial (0 a 499 puntos).
  bronce,

  /// Nivel Plata (500 a 1.499 puntos).
  plata,

  /// Nivel Oro (1.500 a 2.999 puntos).
  oro,

  /// Nivel Platinum (3.000+ puntos).
  platinum,
}

/// Información completa de nivel y gamificación del cliente.
class MockTierInfo {
  /// Crea la información de nivel.
  const new({
    required this.tier,
    required this.displayName,
    required this.currentPoints,
    required this.nextTierName,
    required this.pointsToNextTier,
    required this.progressPercentage,
    required this.multiplier,
    required this.benefits,
  });

  /// Nivel actual.
  final LoyaltyTier tier;

  /// Nombre legible del nivel (ej. "Oro").
  final String displayName;

  /// Puntos acumulados actualmente.
  final int currentPoints;

  /// Nombre del próximo nivel alcanzable.
  final String? nextTierName;

  /// Puntos requeridos para subir al siguiente nivel.
  final int? pointsToNextTier;

  /// Porcentaje de progreso de 0.0 a 100.0 hacia el siguiente escalón.
  final double progressPercentage;

  /// Multiplicador de puntos otorgado por el nivel.
  final double multiplier;

  /// Lista de beneficios y ventajas exclusivas del nivel.
  final List<String> benefits;
}

/// Notificación dentro de la aplicación para el cliente (HU-23).
class MockNotification {
  /// Crea una notificación mock.
  const new({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.icon,
  });

  /// Identificador único.
  final String id;

  /// Título de la notificación.
  final String title;

  /// Mensaje o contenido detallado.
  final String message;

  /// Tiempo transcurrido legible (ej. "Hace 10 min").
  final String time;

  /// Si fue leída por el usuario.
  final bool isRead;

  /// Icono representativo.
  final String icon;
}

/// Repositorio de datos locales estáticos para la interfaz de Paseo Points.
abstract final class MockData {
  /// Saldo dinámico del usuario cliente.
  static int userBalance = 2450;

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
  static final List<MockTransaction> transactions = [
    const MockTransaction(
      id: 'tx-01',
      date: '03 Oct 2025',
      establishment: 'Compra en Café Aranjuez',
      points: 120,
      type: TransactionType.earned,
      status: 'Ganados',
    ),
    const MockTransaction(
      id: 'tx-02',
      date: '01 Oct 2025',
      establishment: 'Compra en ZARA',
      points: 85,
      type: TransactionType.earned,
      status: 'Ganados',
    ),
    const MockTransaction(
      id: 'tx-03',
      date: '28 Sep 2025',
      establishment: 'Canje de recompensa',
      points: -500,
      type: TransactionType.spent,
      status: 'Canjeados',
    ),
    const MockTransaction(
      id: 'tx-04',
      date: '25 Sep 2025',
      establishment: 'Compra en Sky Games',
      points: 100,
      type: TransactionType.earned,
      status: 'Ganados',
    ),
  ];

  /// Lista de cupones de canje de recompensas (HU-07, HU-12).
  static final List<MockRedemptionCoupon> coupons = [
    const MockRedemptionCoupon(
      id: 'red-001',
      code: 'PA-483921',
      rewardId: 'ben-01',
      rewardTitle: '20% de descuento en Café Aranjuez',
      establishmentName: 'Café Aranjuez',
      customerName: 'Valentina Rodríguez',
      customerPhone: '+591 720 12345',
      pointsSpent: 500,
      status: RedemptionStatus.issued,
      issuedAt: 'Hoy, 10:45',
    ),
  ];

  /// Lista de notificaciones del usuario (HU-23).
  static final List<MockNotification> notifications = [
    const MockNotification(
      id: 'notif-01',
      title: '¡Ganaste 120 puntos!',
      message: 'Por tu compra en Café Aranjuez.',
      time: 'Hace 2 horas',
      isRead: false,
      icon: 'star',
    ),
    const MockNotification(
      id: 'notif-02',
      title: '¡Alcanzaste el Nivel Oro! 🏆',
      message:
          'Ahora acumulas un 20% adicional de puntos en todas tus compras.',
      time: 'Ayer',
      isRead: true,
      icon: 'trophy',
    ),
    const MockNotification(
      id: 'notif-03',
      title: 'Puntos dobles este fin de semana',
      message: 'Aprovecha sábado y domingo en locales gastronómicos.',
      time: 'Hace 2 días',
      isRead: true,
      icon: 'tag',
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

  /// Emite un nuevo cupón de canje si el saldo es suficiente (HU-07).
  static MockRedemptionCoupon? issueCoupon(MockBenefit benefit) {
    if (userBalance < benefit.pointsRequired) {
      return null;
    }
    userBalance -= benefit.pointsRequired;

    // Asigna el código canónico para la recompensa principal
    final code = benefit.id == 'ben-01'
        ? 'PA-483921'
        : 'PA-${100000 + coupons.length * 137 % 900000}';
    coupons.removeWhere((c) => c.code == code);
    final coupon = MockRedemptionCoupon(
      id: 'red-${coupons.length + 1}',
      code: code,
      rewardId: benefit.id,
      rewardTitle: benefit.title,
      establishmentName: benefit.establishment,
      customerName: currentUser.name,
      customerPhone: currentUser.phone,
      pointsSpent: benefit.pointsRequired,
      status: RedemptionStatus.issued,
      issuedAt: 'Ahora mismo',
    );
    coupons.insert(0, coupon);

    // Registra la transacción en el ledger
    transactions.insert(
      0,
      MockTransaction(
        id: 'tx-red-${coupons.length}',
        date: 'Hoy',
        establishment: 'Canje: ${benefit.title}',
        points: -benefit.pointsRequired,
        type: TransactionType.spent,
        status: 'Canjeados',
      ),
    );

    return coupon;
  }

  /// Busca un cupón por su código alfanumérico.
  static MockRedemptionCoupon? findCoupon(String code) {
    final normalized = code.trim().toUpperCase();
    for (final c in coupons) {
      if (c.code.toUpperCase() == normalized) return c;
    }
    return null;
  }

  /// Marca un cupón como consumido por el comercio (HU-12).
  static bool completeRedemption(String code) {
    final coupon = findCoupon(code);
    if (coupon == null || coupon.status != RedemptionStatus.issued) {
      return false;
    }
    final index = coupons.indexOf(coupon);
    coupons[index] = coupon.copyWith(
      status: RedemptionStatus.used,
      usedAt: 'Hoy',
    );
    return true;
  }

  /// Alias de conveniencia para consumar cupón de canje en caja (HU-12).
  static bool completeCoupon(String code) => completeRedemption(code);

  /// Calcula la información de nivel y gamificación según puntos (HU-22).
  static MockTierInfo getTierInfo([int? points]) {
    final pts = points ?? userBalance;
    if (pts >= 3000) {
      return const MockTierInfo(
        tier: LoyaltyTier.platinum,
        displayName: 'Platinum',
        currentPoints: 3000,
        nextTierName: null,
        pointsToNextTier: null,
        progressPercentage: 100,
        multiplier: 1.5,
        benefits: [
          'Multiplicador 1.5x en acumulación de puntos',
          'Acceso preferencial a eventos culturales',
          'Estacionamiento de cortesía en Paseo Aranjuez',
          'Invitaciones VIP a degustaciones gastronómicas',
        ],
      );
    }
    if (pts >= 1500) {
      final progress = ((pts - 1500) / (3000 - 1500)) * 100;
      return MockTierInfo(
        tier: LoyaltyTier.oro,
        displayName: 'Oro',
        currentPoints: pts,
        nextTierName: 'Platinum',
        pointsToNextTier: 3000 - pts,
        progressPercentage: progress.clamp(0.0, 100.0),
        multiplier: 1.2,
        benefits: const [
          'Multiplicador 1.2x en acumulación de puntos',
          'Acceso prioritario a canje de recompensas',
          'Regalo de cumpleaños exclusivo',
          'Descuentos especiales de fin de mes',
        ],
      );
    }
    if (pts >= 500) {
      final progress = ((pts - 500) / (1500 - 500)) * 100;
      return MockTierInfo(
        tier: LoyaltyTier.plata,
        displayName: 'Plata',
        currentPoints: pts,
        nextTierName: 'Oro',
        pointsToNextTier: 1500 - pts,
        progressPercentage: progress.clamp(0.0, 100.0),
        multiplier: 1.1,
        benefits: const [
          'Multiplicador 1.1x en compras seleccionadas',
          'Acceso al catálogo de promociones vigentes',
          'Bono por fechas festivas',
        ],
      );
    }
    final progress = (pts / 500) * 100;
    return MockTierInfo(
      tier: LoyaltyTier.bronce,
      displayName: 'Bronce',
      currentPoints: pts,
      nextTierName: 'Plata',
      pointsToNextTier: 500 - pts,
      progressPercentage: progress.clamp(0.0, 100.0),
      multiplier: 1,
      benefits: const [
        'Acumulación base de 1 punto por compra',
        'Canjes disponibles según catálogo',
      ],
    );
  }
}
