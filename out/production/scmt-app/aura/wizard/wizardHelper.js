/*
 * Copyright (c) 2017, Salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

({

    computeWizardClassNames: function(cmp) {
        var cl = ['slds-wizard--default', cmp.get('v.class')].join(' ');
        cmp.set('v.privateWizardClassNames', cl);
    },

    getSteps: function(cmp) {
        return cmp.get('v.body').filter(function(el, idx) {
            return el.isInstanceOf('c:wizardStep');
        });
    },

    getActiveStep: function(cmp) {
        return this.getSteps(cmp).filter(function(el, idx) {
            return el.get('v.active');
        })[0];
    },

    getStepIndex: function(step, cmp) {
        return this.getSteps(cmp).indexOf(step);
    },

    getStepByIndex: function(idx, cmp) {
        return this.getSteps(cmp)[idx];
    }

})