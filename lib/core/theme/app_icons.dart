import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Vocabulario semántico de iconos de GuIA.
///
/// La aplicación consume Lucide únicamente a través de esta capa para evitar
/// mezclar familias y para poder cambiar un glifo sin recorrer cada pantalla.
abstract class AppIcons {
  AppIcons._();

  static const IconData back = LucideIcons.arrowLeft;
  static const IconData close = LucideIcons.x;
  static const IconData next = LucideIcons.chevronRight;
  static const IconData externalLink = LucideIcons.externalLink;
  static const IconData retry = LucideIcons.refreshCw;
  static const IconData time = LucideIcons.clock3;
  static const IconData notification = LucideIcons.bell;
  static const IconData error = LucideIcons.circleX;
  static const IconData warning = LucideIcons.triangleAlert;
  static const IconData account = LucideIcons.userRound;
  static const IconData search = LucideIcons.search;
  static const IconData searchEmpty = LucideIcons.searchX;
  static const IconData filter = LucideIcons.listFilter;
  static const IconData inbox = LucideIcons.inbox;
  static const IconData home = LucideIcons.house;
  static const IconData purchases = LucideIcons.shoppingBag;
  static const IconData requests = LucideIcons.clipboardList;
  static const IconData offer = LucideIcons.tag;
  static const IconData delivery = LucideIcons.truck;
  static const IconData store = LucideIcons.store;
  static const IconData catalog = LucideIcons.packageOpen;
  static const IconData dashboard = LucideIcons.chartNoAxesColumnIncreasing;
  static const IconData period = LucideIcons.calendarDays;
  static const IconData expand = LucideIcons.chevronDown;

  static const IconData sales = LucideIcons.dollarSign;
  static const IconData opportunity = LucideIcons.target;
  static const IconData conversion = LucideIcons.trendingUp;
  static const IconData cancellation = LucideIcons.circleSlash2;
  static const IconData declined = LucideIcons.circleMinus;
  static const IconData balance = LucideIcons.wallet;
  static const IconData receipt = LucideIcons.receiptText;
  static const IconData trendUp = LucideIcons.trendingUp;
  static const IconData trendDown = LucideIcons.trendingDown;
  static const IconData info = LucideIcons.info;
  static const IconData success = LucideIcons.checkCircle;
  static const IconData contacts = LucideIcons.mousePointerClick;
  static const IconData satisfaction = LucideIcons.smile;

  static const IconData workshop = LucideIcons.warehouse;
  static const IconData mechanic = LucideIcons.wrench;
  static const IconData vehicle = LucideIcons.car;
  static const IconData services = LucideIcons.clipboardList;
  static const IconData presentation = LucideIcons.quote;
  static const IconData location = LucideIcons.mapPin;
  static const IconData map = LucideIcons.mapPinned;

  // Catálogo automotriz. Mantener estos alias semánticos evita que cada
  // pantalla vuelva a inventar su propia mezcla de iconos.
  static const IconData engine = LucideIcons.cog;
  static const IconData transmission = LucideIcons.gitBranch;
  static const IconData suspension = LucideIcons.moveVertical;
  static const IconData brakes = LucideIcons.disc3;
  static const IconData electrical = LucideIcons.plugZap;
  static const IconData bodywork = LucideIcons.paintbrush;
  static const IconData audio = LucideIcons.speaker;
  static const IconData climate = LucideIcons.airVent;
  static const IconData fuel = LucideIcons.fuel;
  static const IconData wheels = LucideIcons.circleDot;
  static const IconData lighting = LucideIcons.lightbulb;

  static const IconData rating = LucideIcons.star;
  static const IconData distance = LucideIcons.navigation;
  static const IconData price = LucideIcons.banknote;
  static const IconData verified = LucideIcons.badgeCheck;
  static const IconData reviews = LucideIcons.messageSquareText;
  static const IconData edit = LucideIcons.pencil;
  static const IconData selected = LucideIcons.check;
  static const IconData unselected = LucideIcons.circle;
  static const IconData favorite = LucideIcons.heart;

  static const IconData call = LucideIcons.phoneCall;
  static const IconData message = LucideIcons.messageCircle;
  static const IconData socialContact = LucideIcons.atSign;
  static const IconData otherContact = LucideIcons.circleEllipsis;
  static const IconData send = LucideIcons.send;

  static const IconData connectivityError = LucideIcons.wifiOff;
  static const IconData cloudError = LucideIcons.cloudOff;
}

/// Tamaños aprobados para la familia lineal.
abstract class AppIconSize {
  AppIconSize._();

  static const double inline = 16;
  static const double action = 20;
  static const double leading = 24;
  static const double feature = 32;
  static const double hero = 64;
}

/// Icono Lucide sin placa, círculo ni contenedor decorativo.
///
/// El área táctil pertenece siempre al botón o fila que lo contiene; este
/// widget define únicamente el tratamiento visual del glifo.
class AppLineIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  const AppLineIcon(
    this.icon, {
    super.key,
    this.size = AppIconSize.leading,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: Icon(
          icon,
          size: size,
          color: color,
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }
}
