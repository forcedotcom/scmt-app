/*
 * Copyright (c) 2017, Salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

@isTest
public class MigrationWizardControllerTest {

    static testMethod void testConfig() {
        Map<String, Object> config = MigrationWizardController.config();
        System.assert(config.containsKey('privateServerUrl'));
    }

}