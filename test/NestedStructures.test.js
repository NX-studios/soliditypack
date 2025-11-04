import { expect } from 'chai';
import hre from 'hardhat';
import { decode } from '../lib/decoder.js';

describe('Nested Structures', function () {
    let contract;

    before(async function () {
        const NestedStructuresExample = await hre.ethers.getContractFactory('NestedStructuresExample');
        contract = await NestedStructuresExample.deploy();
    });

    describe('Encoding Nested Structures', function () {
        it('should encode map with nested map', async function () {
            const encoded = await contract.encodeNestedMap();
            console.log('  Encoded:', encoded);

            const decoded = decode(encoded);
            console.log('  Decoded:', JSON.stringify(decoded, null, 4));

            expect(decoded.outer).to.equal(42);
            expect(decoded.nested).to.be.an('object');
            expect(decoded.nested.inner).to.equal(100);
            expect(decoded.nested.name).to.equal('test');
        });

        it('should encode map with array value', async function () {
            const encoded = await contract.encodeMapWithArray();
            const decoded = decode(encoded);

            console.log('  Decoded:', JSON.stringify(decoded, null, 4));

            expect(decoded.name).to.equal('Alice');
            expect(decoded.scores).to.be.an('array').with.lengthOf(3);
            expect(decoded.scores[0]).to.equal(10);
            expect(decoded.scores[1]).to.equal(20);
            expect(decoded.scores[2]).to.equal(30);
        });

        it('should encode complex nested structures', async function () {
            const encoded = await contract.encodeComplexNesting();
            const decoded = decode(encoded);

            console.log('  Decoded:', JSON.stringify(decoded, null, 4));

            expect(decoded.id).to.equal(1);
            expect(decoded.data).to.be.an('object');
            expect(decoded.data.tags).to.be.an('array').with.lengthOf(2);
            expect(decoded.data.tags[0]).to.equal('a');
            expect(decoded.data.tags[1]).to.equal('b');
            expect(decoded.data.active).to.be.true;
            expect(decoded.count).to.equal(5);
        });
    });

    describe('Decoding Nested Structures', function () {
        it('should decode nested map step by step', async function () {
            const [outerValue, nestedInner, nestedName] = await contract.decodeNestedMapStepByStep();

            console.log('  Outer value:', outerValue.toString());
            console.log('  Nested inner:', nestedInner.toString());
            console.log('  Nested name:', nestedName);

            expect(outerValue).to.equal(42n);
            expect(nestedInner).to.equal(100n);
            expect(nestedName).to.equal('test');
        });

        it('should decode map with array using type inspection', async function () {
            const [name, firstScore, scoresCount] = await contract.decodeMapWithArrayUsingInspection();

            console.log('  Name:', name);
            console.log('  First score:', firstScore.toString());
            console.log('  Scores count:', scoresCount.toString());

            expect(name).to.equal('Alice');
            expect(firstScore).to.equal(10n);
            expect(scoresCount).to.equal(3n);
        });

        it('should extract specific fields from complex nesting', async function () {
            const [firstTag, secondTag, foundTags] = await contract.decodeComplexAndExtractTags();

            console.log('  First tag:', firstTag);
            console.log('  Second tag:', secondTag);
            console.log('  Found tags:', foundTags);

            expect(foundTags).to.be.true;
            expect(firstTag).to.equal('a');
            expect(secondTag).to.equal('b');
        });

        it('should skip unknown nested structures', async function () {
            const [id, count] = await contract.decodeUnknownStructureWithSkip();

            console.log('  ID:', id.toString());
            console.log('  Count:', count.toString());
            console.log('  (Skipped the complex "data" nested map entirely)');

            expect(id).to.equal(1n);
            expect(count).to.equal(5n);
        });
    });

    describe('Key Behaviors', function () {
        it('demonstrates that decoder counts entries to know when nesting ends', async function () {
            // When you encode startMap(2), the decoder knows it needs to read exactly:
            // - 2 keys
            // - 2 values
            // If one value is itself a map with startMap(3), that inner map needs:
            // - 3 keys
            // - 3 values
            // Then it returns to reading the outer map's second value

            const encoded = await contract.encodeNestedMap();
            const decoded = decode(encoded);

            // Verify the structure is correct
            expect(Object.keys(decoded)).to.have.lengthOf(2); // Outer map has 2 entries
            expect(Object.keys(decoded.nested)).to.have.lengthOf(2); // Inner map has 2 entries
        });

        it('shows skip() handles nested structures recursively', async function () {
            // When you skip a map, it automatically skips all its contents
            // including any nested maps or arrays inside it

            const [id, count] = await contract.decodeUnknownStructureWithSkip();

            // We only read 'id' and 'count', but successfully skipped
            // the entire complex 'data' field which contained:
            // - A nested map
            // - Which itself contained an array
            // - And a boolean
            expect(id).to.equal(1n);
            expect(count).to.equal(5n);
        });
    });
});
