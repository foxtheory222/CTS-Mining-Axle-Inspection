import 'package:cts_mining_axle_inspection/data/models/inspection_enums.dart';
import 'package:cts_mining_axle_inspection/services/inspection_report_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/persistence_test_helpers.dart';

void main() {
  test(
    'maps customer signature details separately from technician signature',
    () {
      final signedAt = DateTime.utc(2026, 7, 1, 13);
      final inspection = buildInspection(
        id: 'signed-inspection',
        documentNumber: '20260701-0001',
        status: InspectionStatus.complete,
        signatureFilePath: '/tmp/technician-signature.png',
        customerRepresentativeName: 'Morgan Customer',
        customerSignatureFilePath: '/tmp/customer-signature.png',
        customerSignatureDate: signedAt,
      );

      final report = InspectionReportMapper.fromRecord(inspection);

      expect(report.signature?.filePath, '/tmp/technician-signature.png');
      expect(report.customerSignature?.filePath, '/tmp/customer-signature.png');
      expect(report.customerSignature?.signerName, 'Morgan Customer');
      expect(report.customerSignature?.signedAt, signedAt);
    },
  );
}
