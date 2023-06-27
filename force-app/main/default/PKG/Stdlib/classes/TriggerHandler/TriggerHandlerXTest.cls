@isTest
class TriggerHandlerXTest {
    static final String TRIGGER_CONTEXT_ERROR = 'Trigger handler called outside of Trigger execution';
    static String lastMethodCalled;
    static TestHandler handler;

    // test implementation of the TriggerHandler
    class TestHandler extends TriggerHandlerX {
        public override void beforeInsert() { TriggerHandlerXTest.lastMethodCalled = 'beforeInsert'; }
        public override void beforeUpdate() { TriggerHandlerXTest.lastMethodCalled = 'beforeUpdate'; }
        public override void beforeDelete() { TriggerHandlerXTest.lastMethodCalled = 'beforeDelete'; }
        public override void afterInsert() { TriggerHandlerXTest.lastMethodCalled = 'afterInsert'; }
        public override void afterUpdate() { TriggerHandlerXTest.lastMethodCalled = 'afterUpdate'; }
        public override void afterDelete() { TriggerHandlerXTest.lastMethodCalled = 'afterDelete'; }
        public override void afterUndelete() { TriggerHandlerXTest.lastMethodCalled = 'afterUndelete'; }
    }

    static {
        handler = new TestHandler();
        handler.isTriggerExecuting = true; // override its internal trigger detection
    }

    @isTest static void testBeforeInsert() {
        beforeInsertMode();
        handler.run();
        System.assertEquals('beforeInsert', lastMethodCalled, 'last method should be beforeInsert');
    }

    @isTest static void testBeforeUpdate() {
        beforeUpdateMode();
        handler.run();
        System.assertEquals('beforeUpdate', lastMethodCalled, 'last method should be beforeUpdate');
    }

    @isTest static void testBeforeDelete() {
        beforeDeleteMode();
        handler.run();
        System.assertEquals('beforeDelete', lastMethodCalled, 'last method should be beforeDelete');
    }

    @isTest static void testAfterInsert() {
        afterInsertMode();
        handler.run();
        System.assertEquals('afterInsert', lastMethodCalled, 'last method should be afterInsert');
    }

    @isTest static void testAfterUpdate() {
        afterUpdateMode();
        handler.run();
        System.assertEquals('afterUpdate', lastMethodCalled, 'last method should be afterUpdate' );
    }

    @isTest static void testAfterDelete() {
        afterDeleteMode();
        handler.run();
        System.assertEquals('afterDelete', lastMethodCalled, 'last method should be afterDelete');
    }

    @isTest static void testAfterUndelete() {
        afterUndeleteMode();
        handler.run();
        System.assertEquals('afterUndelete', lastMethodCalled, 'last method should be afterUndelete');
    }

    @isTest static void testNonTriggerContext() {
        try {
            handler.run();
            System.assert(false, 'the handler ran but should have thrown');
        } catch (TriggerHandlerX.TriggerHandlerException te) {
            System.assertEquals(TRIGGER_CONTEXT_ERROR, te.getMessage(), 'the exception message should match');
        } catch (Exception e) {
            System.assert(false, 'the exception thrown was not expected: ' + e.getTypeName() + ': ' + e.getMessage());
        }
    }

    @isTest static void testBypassAPI() {
        afterUpdateMode();

        // test a bypass and run handler
        TriggerHandlerX.bypass('TestHandler');
        handler.run();
        System.assertEquals(null, lastMethodCalled, 'last method should be null when bypassed');
        System.assertEquals(true, TriggerHandlerX.isBypassed('TestHandler'), 'test handler should be bypassed');
        resetTest();

        // clear that bypass and run handler
        TriggerHandlerX.clearBypass('TestHandler');
        handler.run();
        System.assertEquals('afterUpdate', lastMethodCalled, 'last method called should be afterUpdate');
        System.assertEquals(false, TriggerHandlerX.isBypassed('TestHandler'), 'test handler should be bypassed');
        resetTest();

        // test a re-bypass and run handler
        TriggerHandlerX.bypass('TestHandler');
        handler.run();
        System.assertEquals(null, lastMethodCalled, 'last method should be null when bypassed');
        System.assertEquals(true, TriggerHandlerX.isBypassed('TestHandler'), 'test handler should be bypassed');
        resetTest();

        // clear all bypasses and run handler
        TriggerHandlerX.clearAllBypasses();
        handler.run();
        System.assertEquals('afterUpdate', lastMethodCalled, 'last method called should be afterUpdate');
        System.assertEquals(false, TriggerHandlerX.isBypassed('TestHandler'), 'test handler should be bypassed');
        resetTest();
    }

    @isTest static void testLoopCount() {
        beforeInsertMode();

        // set the max loops to 2
        handler.setMaxLoopCount(2);

        // run the handler twice
        handler.run();
        handler.run();

        // clear the tests
        resetTest();

        try {
            // try running it. This should exceed the limit.
            handler.run();
            System.assert(false, 'the handler should throw on the 3rd run when maxloopcount is 3');
        } catch (TriggerHandlerX.TriggerHandlerException te) {
            // we're expecting to get here
            System.assertEquals(null, lastMethodCalled, 'last method should be null');
        } catch (Exception e) {
            System.assert(false, 'the exception thrown was not expected: ' + e.getTypeName() + ': ' + e.getMessage());
        }

        // clear the tests
        resetTest();

        // now clear the loop count
        handler.clearMaxLoopCount();

        try {
            // re-run the handler. We shouldn't throw now.
            handler.run();
            System.assertEquals('beforeInsert', lastMethodCalled, 'last method should be beforeInsert');
        } catch (TriggerHandlerX.TriggerHandlerException te) {
            System.assert(false, 'running the handler after clearing the loop count should not throw');
        } catch (Exception e) {
            System.assert(false, 'the exception thrown was not expected: ' + e.getTypeName() + ': ' + e.getMessage());
        }
    }

    @isTest static void testLoopCountClass() {
        TriggerHandlerX.LoopCount lc = new TriggerHandlerX.LoopCount();
        System.assertEquals(5, lc.getMax(), 'max should be five on init');
        System.assertEquals(0, lc.getCount(), 'count should be zero on init');

        lc.increment();
        System.assertEquals(1, lc.getCount(), 'count should be 1');
        System.assertEquals(false, lc.exceeded(),'should not be exceeded with count of 1');

        lc.increment();
        lc.increment();
        lc.increment();
        lc.increment();
        System.assertEquals(5, lc.getCount(), 'count should be 5');
        System.assertEquals(false, lc.exceeded(), 'should not be exceeded with count of 5');

        lc.increment();
        System.assertEquals(6, lc.getCount(), 'count should be 6');
        System.assertEquals(true, lc.exceeded(), 'should not be exceeded with count of 6');
    }

    @isTest static void testGetHandlerName() {
        System.assertEquals('TestHandler', handler.getHandlerName(), 'handler name should match class name');
    }

    @isTest static void testVirtualMethods() {
        TriggerHandlerX h = new TriggerHandlerX();
        h.beforeInsert();
        h.beforeUpdate();
        h.beforeDelete();
        h.afterInsert();
        h.afterUpdate();
        h.afterDelete();
        h.afterUndelete();
    }

    static void resetTest() { lastMethodCalled = null; }
    static void beforeInsertMode() { handler.setTriggerContext('before insert', true); }
    static void beforeUpdateMode() { handler.setTriggerContext('before update', true); }
    static void beforeDeleteMode() { handler.setTriggerContext('before delete', true); }
    static void afterInsertMode() { handler.setTriggerContext('after insert', true); }
    static void afterUpdateMode() { handler.setTriggerContext('after update', true); }
    static void afterDeleteMode() { handler.setTriggerContext('after delete', true); }
    static void afterUndeleteMode() { handler.setTriggerContext('after undelete', true); }
}