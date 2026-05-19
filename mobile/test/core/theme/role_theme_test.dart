import 'package:flutter_test/flutter_test.dart';
import 'package:valet/core/theme/app_colors.dart';
import 'package:valet/core/theme/role_theme.dart';

void main() {
  group('RoleTheme.accentFor', () {
    test('all roles return brand blue (unified accent)', () {
      expect(RoleTheme.accentFor(AppRole.resident), AppColors.rlvBlue);
      expect(RoleTheme.accentFor(AppRole.worker), AppColors.rlvBlue);
      expect(RoleTheme.accentFor(AppRole.propertyManager), AppColors.rlvBlue);
      expect(RoleTheme.accentFor(AppRole.operationsManager), AppColors.rlvBlue);
      expect(RoleTheme.accentFor(AppRole.owner), AppColors.rlvBlue);
    });
  });

  group('RoleTheme.fromString', () {
    test('maps resident string', () {
      expect(RoleTheme.fromString('resident'), AppRole.resident);
    });

    test('maps driver string to worker role', () {
      expect(RoleTheme.fromString('driver'), AppRole.worker);
    });

    test('maps property_manager string', () {
      expect(RoleTheme.fromString('property_manager'), AppRole.propertyManager);
    });

    test('maps operations_manager string', () {
      expect(RoleTheme.fromString('operations_manager'), AppRole.operationsManager);
    });

    test('maps owner string', () {
      expect(RoleTheme.fromString('owner'), AppRole.owner);
    });

    test('maps super_admin string to owner role', () {
      expect(RoleTheme.fromString('super_admin'), AppRole.owner);
    });

    test('isBusinessOwner treats owner and super_admin as same', () {
      expect(RoleTheme.isBusinessOwner('owner'), isTrue);
      expect(RoleTheme.isBusinessOwner('super_admin'), isTrue);
      expect(RoleTheme.isBusinessOwner('driver'), isFalse);
    });

    test('unknown string defaults to resident', () {
      expect(RoleTheme.fromString('unknown_role'), AppRole.resident);
    });
  });
}
