const test = require('node:test');
const assert = require('node:assert/strict');
const { add, subtract } = require('../src/calculator');

test('add returns the sum of two numbers', () => {
  assert.equal(add(2, 3), 5);
});

test('subtract returns the difference of two numbers', () => {
  assert.equal(subtract(5, 3), 2);
});
