import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';

let testEnv:any;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "handz-test",
    firestore: { rules: readFileSync("firestore.rules", "utf8") }
  });
});

afterAll(async () => await testEnv.cleanup());

test("user can read own requests", async () => {
  const alice = testEnv.authenticatedContext("alice");
  const db = alice.firestore();
  const doc = db.collection('requests').doc('r1');
  await testEnv.withSecurityRulesDisabled(async (ctx:any) => {
    await ctx.firestore().collection('requests').doc('r1').set({
      userId: "alice", status: "pending"
    });
  });
  await assertSucceeds(doc.get());
});

test("user cannot read others' requests", async () => {
  const bob = testEnv.authenticatedContext("bob");
  const db = bob.firestore();
  const doc = db.collection('requests').doc('r1');
  await assertFails(doc.get());
});
