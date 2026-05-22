@IsTest(SeeAllData=true)
private class LogisticaDashboardControllerTest {

    @IsTest
    static void testGetDestinoData() {
        Test.startTest();
        List<Map<String, Object>> result = LogisticaDashboardController.getDestinoData();
        Test.stopTest();
        System.assertNotEquals(null, result, 'Resultado não deve ser nulo');
    }

    @IsTest
    static void testGetTransportadoraData() {
        Test.startTest();
        List<Map<String, Object>> result = LogisticaDashboardController.getTransportadoraData();
        Test.stopTest();
        System.assertNotEquals(null, result, 'Resultado não deve ser nulo');
    }

    @IsTest
    static void testGetCasesByEstado() {
        Test.startTest();
        List<Map<String, Object>> result = LogisticaDashboardController.getCasesByEstado('SP');
        Test.stopTest();
        System.assertNotEquals(null, result, 'Resultado não deve ser nulo');
    }

    @IsTest
    static void testGetCasesByTransportadora() {
        Test.startTest();
        List<Map<String, Object>> result = LogisticaDashboardController.getCasesByTransportadora('Jadlog.com');
        Test.stopTest();
        System.assertNotEquals(null, result, 'Resultado não deve ser nulo');
    }
}
