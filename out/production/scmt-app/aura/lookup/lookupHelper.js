/*
 * Copyright (c) 2017, Salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

({

    computeLabel: function(cmp) {
        var value    = cmp.get('v.value')
          , labelVar = cmp.get('v.labelVar')

        if (value && labelVar && value.hasOwnProperty(labelVar)) return value[labelVar];
        return '';
    }

})