
const truffleAssert = require('truffle-assertions');

const TIME_UNIT = {
    DAY: 86400,
    WEEK: 604800,
    MONTH: 2592000,
};

function getEvent(tx, event) {
    return new Promise((resolve, reject) => {
        truffleAssert.eventEmitted(tx, event, resolve);
    });
}

function getRevert(action, m) {
    return new Promise((resolve, reject) => {
        action()
            .catch(resolve)
            .then(() => assert.exists(null, m || "Expected revert but no error thrown"))
            .catch(err => reject());
    });
}

module.exports = { getEvent, getRevert, TIME_UNIT };