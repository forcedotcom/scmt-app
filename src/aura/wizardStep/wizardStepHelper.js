/*
 * Copyright (c) 2017, Salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

({

    computeWizardStepClassNames: function(cmp) {
        var cl = [
            'slds-wizard-step--default',
            cmp.get('v.active') ? 'slds-show' : 'slds-hide',
            cmp.get('v.class')
        ].join(' ');
        cmp.set('v.privateWizardStepClassNames', cl);
    },

    callOnActive: function(cmp) {
        var onactive = cmp.get('v.onactive');
        if (cmp.get('v.active') && onactive) $A.enqueueAction(onactive);
    }

})