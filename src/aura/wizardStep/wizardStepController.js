/*
 * Copyright (c) 2017, Salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

({

    init: function(cmp, evt, helper) {
        helper.computeWizardStepClassNames(cmp);
        helper.callOnActive(cmp);
    },

    handleWizardStepClassNameChange: function(cmp, evt, helper) {
        helper.computeWizardStepClassNames(cmp);
    },

    handleWizardStepActiveChange: function(cmp, evt, helper) {
        helper.computeWizardStepClassNames(cmp);
        helper.callOnActive(cmp);
    }

})