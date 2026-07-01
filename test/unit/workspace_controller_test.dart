import 'package:flutter_test/flutter_test.dart';

import 'package:cts_mining_axle_inspection/core/mining_axle_template.dart';
import 'package:cts_mining_axle_inspection/core/workspace_controller.dart';

void main() {
  test('document numbers increment and search filters records', () {
    final controller = AppWorkspaceController();

    final created = controller.createInspection();
    expect(created.documentNumber, matches(RegExp(r'^\d{8}-\d{4}$')));

    final duplicate = controller.duplicateInspection(
      controller.inspections.first,
    );
    expect(duplicate.documentNumber, isNot(equals(created.documentNumber)));
    expect(duplicate.sections.length, MiningAxleTemplate.sections.length);

    controller.setSearchQuery('North Basin');
    expect(controller.filteredInspections.length, 1);
    expect(
      controller.filteredInspections.first.customer,
      'North Basin Processing',
    );
  });
}
