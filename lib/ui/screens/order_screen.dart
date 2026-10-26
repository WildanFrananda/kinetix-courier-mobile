import 'dart:convert';
import 'dart:typed_data';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/state/order_ui_state.dart';
import 'package:fleet_pulse_mobile/viewmodels/order_view_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';

part '../widgets/order/cancelled_view.dart';
part '../widgets/order/order_view.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({required this.order, super.key});

  final Order order;

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrderViewModel>().bind(widget.order);
  }

  @override
  Widget build(BuildContext context) {
    final OrderViewModel vm = context.watch<OrderViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text('Order #${widget.order.id.value}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: switch (vm.state) {
            OrderCancelled() => _CancelledView(
              title: 'Order cancelled',
              onBack: vm.back,
            ),
            OrderUnassigned() => _CancelledView(
              title: 'Dispatch has taken this job off you',
              onBack: vm.back,
            ),
            OrderNoLongerActive() => _CancelledView(
              title: 'This job is no longer active for you',
              onBack: vm.back,
            ),
            OrderShowing(
              :final Order order,
              :final bool submitting,
              :final Failure? error,
            ) =>
              _OrderView(
                vm: vm,
                order: order,
                submitting: submitting,
                error: error?.message,
              ),
          },
        ),
      ),
    );
  }
}
