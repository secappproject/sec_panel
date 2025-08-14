class BusbarRemark {
  final String vendorName;
  final String? remark;
  final String vendorId;

  BusbarRemark({required this.vendorName, this.remark, required this.vendorId});

  factory BusbarRemark.fromJson(Map<String, dynamic> json) {
    return BusbarRemark(
      vendorName: json['vendor_name'] ?? '',
      remark: json['remark'],
      vendorId: json['vendor_id'] ?? '',
    );
  }
}
