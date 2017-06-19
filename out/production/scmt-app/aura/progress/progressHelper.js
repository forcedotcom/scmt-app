/*
 * Copyright (c) 2017, Salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

({

    convertItems: function(items, active) {
        return items.map(function(el, idx) {
            var def = {
                label: 'Step ' + (idx + 1),
                isComplete: (idx < active),
                isError: false,
                isActive: (active === idx)
             };

            if (typeof el === 'string') el = { label: el };
            if (!(typeof el === 'object' && el !== null && !Array.isArray(el))) el = { label: el.toString() };
            return Object.assign({}, def, el);
        });
    },

    computeClass: function(cls, theme) {
        cls = cls || '';

        if (theme && theme !== '') {
            cls = cls + ' slds-progress--' + theme;
        }

        return 'slds-progress ' + cls;
    },

    computeProgress: function(active, totalItems) {
        return (active === 0 ? 0 : (100 / (totalItems - 1) * active));
    }

})