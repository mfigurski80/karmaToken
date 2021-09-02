
const truffleAssert = require('truffle-assertions');

const TIME_UNIT = {
    DAY: 86400,
    WEEK: 604800,
    MONTH: 2592000,
};

function now() {
    return Math.floor(Date.now() / 1000);
}

function getEvent(tx, event) {
    return new Promise((resolve, reject) => {
        truffleAssert.eventEmitted(tx, event, resolve);
    });
}

function getRevert(prom, m) {
    return new Promise((resolve, reject) => {
        prom
            .catch(resolve)
            .then(() => assert.exists(null, m || "Expected revert but no error thrown"))
            .catch(reject);
    });
}

module.exports = { getEvent, getRevert, now, TIME_UNIT };