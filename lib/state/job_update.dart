import 'package:kinetix_courier/models/ids.dart';
import 'package:kinetix_courier/models/order.dart';

sealed class JobUpdate {
  const JobUpdate();
}

class JobActive extends JobUpdate {
  const JobActive(this.order);

  final Order order;
}

class JobNone extends JobUpdate {
  const JobNone();
}

class JobCancelled extends JobUpdate {
  const JobCancelled(this.id);

  final OrderId id;
}

class JobUnassigned extends JobUpdate {
  const JobUnassigned(this.id);

  final OrderId id;
}
