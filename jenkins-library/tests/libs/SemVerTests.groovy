
import groovy.util.GroovyTestCase

class SemVerTests extends GroovyTestCase {

    void SemVerTests() {
        
        assertEquals 'v1.0.1', SemVer.bump('v1.0.0')
        assertEquals 'v1.0.0', SemVer.bump('')

        assertEquals '1.2.4', SemVer.bump('1.2.3')
        assertEquals '1.2.4', SemVer.bump('1.2.3', 'PATCH')

        assertEquals '1.3.0', SemVer.bump('1.2.3', 'MINOR')
        assertEquals '1.3', SemVer.bump('1.2', 'MINOR')

        assertEquals '2.0.0', SemVer.bump('1.2.3', 'MAJOR')
        assertEquals '2.0', SemVer.bump('1.2', 'MAJOR')

        assertEquals '1.3.0.0', SemVer.bump('1.2.3.4', 'MINOR')

        assertEquals '1.3.0-SNAPSHOT', SemVer.bump('1.2.3-SNAPSHOT', 'MINOR')
        assertEquals '1.3-SNAPSHOT', SemVer.bump('1.2-SNAPSHOT', 'MINOR')


        // also by index
        assertEquals '1.2.4', SemVer.bump('1.2.3', '-1')
        assertEquals '1.3.0', SemVer.bump('1.2.3', '-2')
        assertEquals '1.3.0.0', SemVer.bump('1.2.3.4', '-3')
        //from the front
        assertEquals '1.2.4', SemVer.bump('1.2.3', '2')
        assertEquals '1.3.0.0', SemVer.bump('1.2.3.4', '1')
        assertEquals '2.0.0.0', SemVer.bump('1.2.3.4', '0')


        // bump PATCH that doesn't exist
        expect_exception{ SemVer.bump('1.2', 'PATCH') }
    }


    /**
     * Groovy's Junit doesn't seem to support @Test(expect)
     */
    private void expect_exception(def closure) {
        try {
            with closure
            fail "Exception was never thrown"
        } catch (Exception x) {}
    }
}
