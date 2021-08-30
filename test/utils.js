
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

function getRevert(action) {
    return new Promise((resolve, reject) => {
        action()
            .then(() => assert.fail() && reject())
            .catch(resolve);
    });
}

module.exports = { getEvent, getRevert, TIME_UNIT };