/**
 * This evolved from pure SemVer to any-length version with optional -suffix
 * accepts any of:
 * 1
 * 1.2
 * 1.2.3
 * 1.2.3.4 (etc, no limit)
 * 1.2.3-SNAPSHOT
 *
 */

package libs

class SemVer implements Serializable {

    enum PatchLevel {
        MAJOR, MINOR, PATCH
    }

    private int[] components
    private String suffix = ''
    private String prefix = ''

    SemVer(String version) {
        if (version.contains('-')) {
            suffix = version.substring(version.indexOf('-'))
            version = version - suffix
        }
        if (version.contains('v')) {
            prefix = 'v'
            version = version.substring(1)
        }

        components = version.tokenize('.').collect{it.toInteger()}
    }

    SemVer(int major, int minor, int patch) {
        this.components = [major, minor, patch]
    }


    SemVer bump(int componentIndex) {
        // from the end or front?
        def index = (componentIndex < 0) ? components.size() + componentIndex : componentIndex
        if (components.size() <= index) {
            throw new IllegalArgumentException("Can't bump index ${componentIndex} of version ${toString()} because we don't have enough components")
        }

        components[index]++

        // reset all following digits to 0
        for (int i = index + 1 ; i < components.size() ; i++) {
            components[i] = 0
        }
        return this
    }

    SemVer bump(PatchLevel patchLevel) {
        // convert to index
        bump(PatchLevel.findIndexOf {it == patchLevel})
    }

    /**
     * One-line convenience static method.
     * @param version - a string version with optional -suffix.
     * @param patchLevel - which version component to increment.
     *      One of:
     *          * string name for the enum constant,
     *          * relative array index (eg -1 or "-1" for last component)
     * @return string version after bumping:
     */
    static String bump(String version, def patchLevel = -1) {

        if (version.isEmpty()) {
         return "v1.0.0"
        }

        def semVer = new SemVer(version)
        PatchLevel level
        if (!PatchLevel.any{it.name() == patchLevel}) {
            // Not a valid enum element name,
            // this must be an integer index in the provided version.
            semVer.bump(patchLevel.toInteger()).toString()
        } else {
            semVer.bump(PatchLevel.valueOf(patchLevel)).toString()
        }
    }

    /**
     * @return the number of version numeric components
     */
    int size() {
        return components.size()
    }

    String toString() {
        return "${prefix}${components.join('.')}${suffix}"
    }

    static void main(String... args) {
      println SemVer.bump('1.0.0', 'MAJOR')
      println SemVer.bump('1.0.0')
      println SemVer.bump('v1.0.1')
      println SemVer.bump('')
    }
}