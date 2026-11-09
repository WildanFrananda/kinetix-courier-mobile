part of '../../screens/order_screen.dart';

class _OrderView extends StatelessWidget {
  const _OrderView({
    required this.vm,
    required this.order,
    required this.submitting,
    required this.error,
  });

  static const double _photoMaxSide = 1920;
  static const int _photoQuality = 85;

  final OrderViewModel vm;
  final Order order;
  final bool submitting;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final bool canPickup = order.status == OrderStatus.assigned;
    final bool pickedUp = order.status == OrderStatus.pickedUp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Status: ${order.status.name}'),
        Text('Weight: ${order.weightKg} kg'),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Pickup: ${order.pickup.latitude}, ${order.pickup.longitude}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.navigation_outlined),
            onPressed: vm.navigateToPickup,
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Dropoff: ${order.dropoff.latitude}, ${order.dropoff.longitude}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.navigation_outlined),
            onPressed: vm.navigateToDropoff,
          ),
        ),
        if (pickedUp) ...<Widget>[
          const Divider(height: 24),
          const Text(
            'Proof of Delivery (POD)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(
                    vm.podPhotoUrl != null
                        ? Icons.check_circle
                        : Icons.camera_alt,
                    color: vm.podPhotoUrl != null ? Colors.green : null,
                  ),
                  label: Text(
                    vm.photoUploading
                        ? 'Uploading Photo'
                        : vm.podPhotoUrl != null
                        ? 'Photo Attached'
                        : 'Capture Photo',
                  ),
                  onPressed: vm.photoUploading
                      ? null
                      : () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? photo = await picker.pickImage(
                            source: ImageSource.camera,
                            maxWidth: _photoMaxSide,
                            maxHeight: _photoMaxSide,
                            imageQuality: _photoQuality,
                            requestFullMetadata: false,
                          );

                          if (photo != null) {
                            await vm.attachPhoto(photo.path);
                          }
                        },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(
                    vm.podSignature != null ? Icons.check_circle : Icons.draw,
                    color: vm.podSignature != null ? Colors.green : null,
                  ),
                  label: Text(
                    vm.podSignature != null ? 'Signed' : 'Add Signature',
                  ),
                  onPressed: () async {
                    final SignatureController controller = SignatureController(
                      penStrokeWidth: 3,
                      penColor: Colors.black,
                      exportBackgroundColor: Colors.white,
                    );
                    final Uint8List? signatureBytes =
                        await showDialog<Uint8List>(
                          context: context,
                          builder: (BuildContext ctx) {
                            return AlertDialog(
                              title: const Text('Customer Signature'),
                              content: SizedBox(
                                width: 300,
                                height: 200,
                                child: Signature(
                                  controller: controller,
                                  backgroundColor: Colors.grey.shade200,
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: controller.clear,
                                  child: const Text('Clear'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final Uint8List? bytes = await controller
                                        .toPngBytes();
                                    if (ctx.mounted) {
                                      Navigator.of(ctx).pop(bytes);
                                    }
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            );
                          },
                        );

                    if (signatureBytes != null && signatureBytes.isNotEmpty) {
                      final String base64Sig =
                          'data:image/png;base64,${base64Encode(signatureBytes)}';
                      await vm.setPodSignature(base64Sig);
                    }
                  },
                ),
              ),
            ],
          ),
          if (vm.podPhotoUrl == null || vm.podSignature == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                "A photo of the parcel and the receiver's signature are both "
                'required.',
              ),
            ),
        ],
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Error: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        const Spacer(),
        if (canPickup)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: submitting ? null : vm.pickup,
              child: submitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Mark as Picked Up'),
            ),
          ),
        if (pickedUp)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: vm.canDeliver ? vm.delivered : null,
              child: submitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Mark as Delivered'),
            ),
          ),
      ],
    );
  }
}
