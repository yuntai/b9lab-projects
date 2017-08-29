pragma solidity ^0.4.0;

/// @title Library which implements a semver datatype and comparisons.
/// @author Piper Merriam <pipermerriam@gmail.com>
library SemVersionLib {
  struct SemVersion {
    bytes32 hash;
    uint32 major;
    uint32 minor;
    uint32 patch;
    string preRelease;
    string build;
    string[] preReleaseIdentifiers;
  }

  enum Comparison {
    Before,
    Same,
    After
  }

  /// @dev Initialize a SemVersion struct
  /// @param self The SemVersion object to initialize.
  /// @param major The major portion of the semver version string.
  /// @param minor The minor portion of the semver version string.
  /// @param patch The patch portion of the semver version string.
  /// @param preRelease The pre-release portion of the semver version string.  Use empty string if the version string has no pre-release portion.
  /// @param build The build portion of the semver version string.  Use empty string if the version string has no build portion.
  function init(SemVersion storage self,
                uint32 major,
                uint32 minor,
                uint32 patch,
                string preRelease,
                string build) public returns (bool) {
    self.major = major;
    self.minor = minor;
    self.patch = patch;
    self.preRelease = preRelease;
    self.preReleaseIdentifiers = splitIdentifiers(preRelease);
    self.build = build;
    self.hash = sha3(major, minor, patch, preRelease);
    return true;
  }

  //
  // Storage Operations
  //
  /// @dev Return boolean indicating if the two SemVersion objects are considered equal
  /// @param self The first SemVersion
  /// @param other The second SemVersion
  function isEqual(SemVersion storage self, SemVersion storage other) public returns (bool) {
    return self.hash == other.hash;
  }

  /// @dev Return boolean indicating if the first SemVersion object is considered strictly greater than the second.
  /// @param self The first SemVersion
  /// @param other The second SemVersion
  function isGreater(SemVersion storage self, SemVersion storage other) public returns (bool) {
    if (self.hash == other.hash) {
      return false;
    } else if (self.major > other.major) {
      return true;
    } else if (self.major < other.major) {
      return false;
    } else if (self.minor > other.minor) {
      return true;
    } else if (self.minor < other.minor) {
      return false;
    } else if (self.patch > other.patch) {
      return true;
    } else if (self.patch < other.patch) {
      return false;
    } else if (!isPreRelease(self) && isPreRelease(other)) {
      return true;
    } else if (isPreRelease(self) && !isPreRelease(other)) {
      return false;
    } else if (isPreReleaseGreater(self, other)) {
      return true;
    } else {
      return false;
    }
  }

  /// @dev Return boolean indicating if the first SemVersion object is considered greater than or equal to the second.
  /// @param self The first SemVersion
  /// @param other The second SemVersion
  function isGreaterOrEqual(SemVersion storage self, SemVersion storage other) public returns (bool) {
    return isEqual(self, other) || isGreater(self, other);
  }

  /*
   *  PreRelease comparisons
   */
  /// @dev Return boolean indicating if the pre-release string from the first SemVersion object is considered greater than the pre-release string from the second SemVersion object.
  /// @param left The first SemVersion
  /// @param right The second SemVersion
  function isPreReleaseGreater(SemVersion storage left, SemVersion storage right) internal returns (bool) {
    return comparePreReleases(left, right) == Comparison.After;
  }

  /// @dev Return boolean indicating if the provided SemVersion is a pre-release.
  /// @param self The SemVersion
  function isPreRelease(SemVersion storage self) internal returns (bool) {
    return self.preReleaseIdentifiers.length > 0;
  }

  /// @dev Return a comparison of the pre-release strings for the two provided SemVersion objects.
  /// @param left The first SemVersion
  /// @param right The second SemVersion
  function comparePreReleases(SemVersion storage left, SemVersion storage right) internal returns (Comparison comparisonResult) {
    uint minLength = min(left.preReleaseIdentifiers.length,
                         right.preReleaseIdentifiers.length);
    for (uint i = 0; i < minLength; i++) {
      if (isNumericString(left.preReleaseIdentifiers[i]) && isNumericString(right.preReleaseIdentifiers[i])) {
        comparisonResult = compareNumericStrings(left.preReleaseIdentifiers[i], right.preReleaseIdentifiers[i]);
      } else {
        comparisonResult = compareStrings(left.preReleaseIdentifiers[i], right.preReleaseIdentifiers[i]);
      }

      if (comparisonResult != Comparison.Same) {
        return comparisonResult;
      }
      continue;
    }

    if (left.preReleaseIdentifiers.length < right.preReleaseIdentifiers.length) {
      return Comparison.Before;
    } else if (left.preReleaseIdentifiers.length > right.preReleaseIdentifiers.length) {
      return Comparison.After;
    } else {
      return Comparison.Same;
    }
  }

  //
  // PreRelease String Utils
  //
  /// @dev Return a comparison based on the ASCII ordering of the two strings
  /// @param left The first string
  /// @param right The second string
  function compareStrings(string left, string right) internal returns (Comparison) {
    for (uint i = 0; i < min(bytes(left).length, bytes(right).length); i++) {
      if (bytes(left)[i] == bytes(right)[i]) {
        continue;
      } else if (uint(bytes(left)[i]) < uint(bytes(right)[i])) {
        return Comparison.Before;
      } else {
        return Comparison.After;
      }
    }

    if (bytes(left).length < bytes(right).length) {
      return Comparison.Before;
    } else if (bytes(left).length > bytes(right).length) {
      return Comparison.After;
    } else {
      return Comparison.Same;
    }
  }

  /// @dev Return a comparison based on the integer representation of the two string.
  /// @param left The first string
  /// @param right The second string
  function compareNumericStrings(string left, string right) internal returns (Comparison) {
    uint leftAsNumber = castStringToUInt(left);
    uint rightAsNumber = castStringToUInt(right);

    if (leftAsNumber < rightAsNumber) {
      return Comparison.Before;
    } else if (leftAsNumber > rightAsNumber) {
      return Comparison.After;
    } else {
      return Comparison.Same;
    }
  }

  /// @dev Splits a string on periods.
  /// @param preRelease The string to split.
  function splitIdentifiers(string preRelease) internal returns (string[]) {
    if (bytes(preRelease).length == 0) {
      return new string[](0);
    }

    uint i;
    uint leftBound = 0;
    uint numIdentifiers = 1;

    for (i = 0; i < bytes(preRelease).length; i++) {
      if (bytes(preRelease)[i] == PERIOD) {
        numIdentifiers += 1;
      }
    }

    string[] memory preReleaseIdentifiers = new string[](numIdentifiers);

    numIdentifiers = 0;

    for (i = 0; i <= bytes(preRelease).length; i++) {
      if (i == bytes(preRelease).length || bytes(preRelease)[i] == PERIOD) {
        uint identifierLength = i - leftBound;

        bytes memory buffer = new bytes(identifierLength);
        for (uint j = 0; j < identifierLength; j++) {
          buffer[j] = bytes(preRelease)[j + leftBound];
        }
        preReleaseIdentifiers[numIdentifiers] = string(buffer);
        leftBound = i + 1;
        numIdentifiers += 1;
      }
    }
    return preReleaseIdentifiers;
  }

  //
  // Math utils
  //
  /// @dev Returns the minimum of two unsigned integers
  /// @param a The first unsigned integer
  /// @param b The first unsigned integer
  function min(uint a, uint b) internal returns (uint) {
    if (a <= b) {
      return a;
    } else {
      return b;
    }
  }

  //
  // Char Utils
  //
  uint constant DIGIT_0 = uint(bytes1('0'));
  uint constant DIGIT_9 = uint(bytes1('9'));
  bytes1 constant PERIOD = bytes1('.');

  /// @dev Returns boolean indicating if the provided character is a numeric digit.
  /// @param v The character to check.
  function isDigit(bytes1 v) internal returns (bool) {
    return (uint(v) >= DIGIT_0 && uint(v) <= DIGIT_9);
  }

  //
  // String Utils
  //
  /// @dev Returns boolean indicating if the provided string is all numeric.
  /// @param value The string to check.
  function isNumericString(string value) internal returns (bool) {
    for (uint i = 0; i < bytes(value).length; i++) {
      if (!isDigit(bytes(value)[i])) {
        return false;
      }
    }

    return bytes(value).length > 0;
  }

  /// @dev Returns the integer representation of a numeric string.
  /// @param numericString The string to convert.
  function castStringToUInt(string numericString) internal returns (uint) {
    uint value = 0;

    for (uint i = 0; i < bytes(numericString).length; i++) {
      value *= 10;
      value += uint(bytes(numericString)[i]) - 48;
    }

    return value;
  }

  /// @dev Concatenates the two strings together.
  /// @param _head The first string
  /// @param tail The second string
  function concat(string storage _head, string tail) returns (bool) {
    bytes head = bytes(_head);

    for (uint i = 0; i < bytes(tail).length; i++) {
      head.push(bytes(tail)[i]);
    }

    _head = string(head);

    return true;
  }

  /// @dev Concatenates the provided byte to the end of the provided string.
  /// @param value The string to append the byte to.
  /// @param b The byte.
  function concatByte(string storage value, bytes1 b) returns (bool) {
    bytes memory _b = new bytes(1);
    _b[0] = b;
    return concat(value, string(_b));
  }
}
/// @title Library implementing an array type which allows O(1) lookups on values.
/// @author Piper Merriam <pipermerriam@gmail.com>
library IndexedOrderedSetLib {
  struct IndexedOrderedSet {
    bytes32[] _values;
    mapping (bytes32 => uint) _valueIndices;
    mapping (bytes32 => bool) _exists;
  }

  modifier requireValue(IndexedOrderedSet storage self, bytes32 value) {
    if (contains(self, value)) {
      _;
    } else {
      throw;
    }
  }

  /// @dev Returns the size of the set
  /// @param self The set
  function size(IndexedOrderedSet storage self) constant returns (uint) {
    return self._values.length;
  }

  /// @dev Returns boolean if the key is in the set
  /// @param self The set
  /// @param value The value to check
  function contains(IndexedOrderedSet storage self, bytes32 value) constant returns (bool) {
    return self._exists[value];
  }

  /// @dev Returns the index of the value in the set.
  /// @param self The set
  /// @param value The value to look up the index for.
  function indexOf(IndexedOrderedSet storage self, bytes32 value) requireValue(self, value) 
                                                                  constant 
                                                                  returns (uint) {
    return self._valueIndices[value];
  }

  /// @dev Removes the element at index idx from the set and returns it.
  /// @param self The set
  /// @param idx The index to remove and return.
  function pop(IndexedOrderedSet storage self, uint idx) public returns (bytes32) {
    bytes32 value = get(self, idx);

    if (idx != self._values.length - 1) {
      bytes32 movedValue = self._values[self._values.length - 1];
      self._values[idx] = movedValue;
      self._valueIndices[movedValue] = idx;
    }
    self._values.length -= 1;

    delete self._valueIndices[value];
    delete self._exists[value];

    return value;
  }

  /// @dev Removes the element at index idx from the set
  /// @param self The set
  /// @param value The value to remove from the set.
  function remove(IndexedOrderedSet storage self, bytes32 value) requireValue(self, value)
                                                                 public 
                                                                 returns (bool) {
    uint idx = indexOf(self, value);
    pop(self, idx);
    return true;
  }

  /// @dev Retrieves the element at the provided index.
  /// @param self The set
  /// @param idx The index to retrieve.
  function get(IndexedOrderedSet storage self, uint idx) public returns (bytes32) {
    return self._values[idx];
  }

  /// @dev Pushes the new value onto the set
  /// @param self The set
  /// @param value The value to push.
  function add(IndexedOrderedSet storage self, bytes32 value) public returns (bool) {
    if (contains(self, value)) return true;

    self._valueIndices[value] = self._values.length;
    self._values.push(value);
    self._exists[value] = true;

    return true;
  }
}
contract Authority {
    function canCall(address callerAddress,
                     address codeAddress,
                     bytes4 sig) constant returns (bool);
}


contract AuthorizedInterface {
    address public owner;
    Authority public authority;

    modifier auth {
        if (!isAuthorized()) throw;
        _;
    }

    event OwnerUpdate(address indexed oldOwner, address indexed newOwner);
    event AuthorityUpdate(address indexed oldAuthority, address indexed newAuthority);

    function setOwner(address newOwner) public auth returns (bool);

    function setAuthority(Authority newAuthority) public auth returns (bool);

    function isAuthorized() internal returns (bool);
}


contract Authorized is AuthorizedInterface {
    function Authorized() {
        owner = msg.sender;
        OwnerUpdate(0x0, owner);
    }

    function setOwner(address newOwner) public auth returns (bool) {
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function setAuthority(Authority newAuthority) public auth returns (bool) {
        AuthorityUpdate(authority, newAuthority);
        authority = newAuthority;
        return true;
    }

    function isAuthorized() internal returns (bool) {
        if (msg.sender == owner) {
            return true;
        } else if (address(authority) == (0)) {
            return false;
        } else {
            return authority.canCall(msg.sender, this, msg.sig);
        }
    }
}


contract WhitelistAuthorityInterface is Authority, AuthorizedInterface {
    event SetCanCall(address indexed callerAddress,
                     address indexed codeAddress,
                     bytes4 indexed sig,
                     bool can);

    event SetAnyoneCanCall(address indexed codeAddress,
                           bytes4 indexed sig,
                           bool can);

    function setCanCall(address callerAddress,
                        address codeAddress,
                        bytes4 sig,
                        bool can) auth public returns (bool);

    function setAnyoneCanCall(address codeAddress,
                              bytes4 sig,
                              bool can) auth public returns (bool);
}


contract WhitelistAuthority is WhitelistAuthorityInterface, Authorized {
    mapping (address =>
             mapping (address =>
                      mapping (bytes4 => bool))) _canCall;
    mapping (address => mapping (bytes4 => bool)) _anyoneCanCall;

    function canCall(address callerAddress,
                     address codeAddress,
                     bytes4 sig) constant returns (bool) {
        if (_anyoneCanCall[codeAddress][sig]) {
          return true;
        } else {
          return _canCall[callerAddress][codeAddress][sig];
        }
    }

    function setCanCall(address callerAddress,
                        address codeAddress,
                        bytes4 sig,
                        bool can) auth public returns (bool) {
        _canCall[callerAddress][codeAddress][sig] = can;
        SetCanCall(callerAddress, codeAddress, sig, can);
        return true;
    }

    function setAnyoneCanCall(address codeAddress,
                              bytes4 sig,
                              bool can) auth public returns (bool) {
        _anyoneCanCall[codeAddress][sig] = can;
        SetAnyoneCanCall(codeAddress, sig, can);
        return true;
    }
}
/// @title Database contract for a package index package data.
/// @author Tim Coulter <tim.coulter@consensys.net>, Piper Merriam <pipermerriam@gmail.com>
contract PackageDB is Authorized {
  using SemVersionLib for SemVersionLib.SemVersion;
  using IndexedOrderedSetLib for IndexedOrderedSetLib.IndexedOrderedSet;

  struct Package {
      bool exists;
      uint createdAt;
      uint updatedAt;
      string name;
      address owner;
  }

  // Package Data: (nameHash => value)
  mapping (bytes32 => Package) _recordedPackages;
  IndexedOrderedSetLib.IndexedOrderedSet _allPackageNameHashes;

  // Events
  event PackageReleaseAdd(bytes32 indexed nameHash, bytes32 indexed releaseHash);
  event PackageReleaseRemove(bytes32 indexed nameHash, bytes32 indexed releaseHash);
  event PackageCreate(bytes32 indexed nameHash);
  event PackageDelete(bytes32 indexed nameHash, string reason);
  event PackageOwnerUpdate(bytes32 indexed nameHash, address indexed oldOwner, address indexed newOwner);

  /*
   *  Modifiers
   */
  modifier onlyIfPackageExists(bytes32 nameHash) {
    if (packageExists(nameHash)) {
      _;
    } else {
      throw;
    }
  }

  //
  //  +-------------+
  //  |  Write API  |
  //  +-------------+
  //

  /// @dev Creates or updates a release for a package.  Returns success.
  /// @param name Package name
  function setPackage(string name) public auth returns (bool){
    // Hash the name and the version for storing data
    bytes32 nameHash = hashName(name);

    var package = _recordedPackages[nameHash];

    // Mark the package as existing if it isn't already tracked.
    if (!packageExists(nameHash)) {

      // Set package data
      package.exists = true;
      package.createdAt = now;
      package.name = name;

      // Add the nameHash to the list of all package nameHashes.
      _allPackageNameHashes.add(nameHash);

      PackageCreate(nameHash);
    }

    package.updatedAt = now;

    return true;
  }

  /// @dev Removes a package from the package db.  Packages with existing releases may not be removed.  Returns success.
  /// @param nameHash The name hash of a package.
  function removePackage(bytes32 nameHash, string reason) public 
                                                          auth 
                                                          onlyIfPackageExists(nameHash) 
                                                          returns (bool) {
    PackageDelete(nameHash, reason);

    delete _recordedPackages[nameHash];
    _allPackageNameHashes.remove(nameHash);

    return true;
  }

  /// @dev Sets the owner of a package to the provided address.  Returns success.
  /// @param nameHash The name hash of a package.
  /// @param newPackageOwner The address of the new owner.
  function setPackageOwner(bytes32 nameHash,
                           address newPackageOwner) public 
                                                    auth 
                                                    onlyIfPackageExists(nameHash)
                                                    returns (bool) {
    PackageOwnerUpdate(nameHash, _recordedPackages[nameHash].owner, newPackageOwner);

    _recordedPackages[nameHash].owner = newPackageOwner;
    _recordedPackages[nameHash].updatedAt = now;

    return true;
  }

  //
  //  +------------+
  //  |  Read API  |
  //  +------------+
  //

  /// @dev Query the existence of a package with the given name.  Returns boolean indicating whether the package exists.
  /// @param nameHash The name hash of a package.
  function packageExists(bytes32 nameHash) constant returns (bool) {
    return _recordedPackages[nameHash].exists;
  }

  /// @dev Return the total number of packages
  function getNumPackages() constant returns (uint) {
    return _allPackageNameHashes.size();
  }

  /// @dev Returns package namehash at the provided index from the set of all known name hashes.
  /// @param idx The index of the package name hash to retrieve.
  function getPackageNameHash(uint idx) constant returns (bytes32) {
    return _allPackageNameHashes.get(idx);
  }

  /// @dev Returns information about the package.
  /// @param nameHash The name hash to look up.
  function getPackageData(bytes32 nameHash) constant 
                                            onlyIfPackageExists(nameHash) 
                                            returns (address packageOwner,
                                                     uint createdAt,
                                                     uint updatedAt) {
    var package = _recordedPackages[nameHash];
    return (package.owner, package.createdAt, package.updatedAt);
  }

  /// @dev Returns the package name for the given namehash
  /// @param nameHash The name hash to look up.
  function getPackageName(bytes32 nameHash) constant 
                                            onlyIfPackageExists(nameHash) 
                                            returns (string) {
    return _recordedPackages[nameHash].name;
  }

  /*
   *  Hash Functions
   */
  /// @dev Returns name hash for a given package name.
  /// @param name Package name
  function hashName(string name) constant returns (bytes32) {
    return sha3(name);
  }
}
contract ReleaseDB is Authorized {
  using SemVersionLib for SemVersionLib.SemVersion;
  using IndexedOrderedSetLib for IndexedOrderedSetLib.IndexedOrderedSet;

  struct Release {
    bool exists;
    uint createdAt;
    uint updatedAt;
    bytes32 nameHash;
    bytes32 versionHash;
    string releaseLockfileURI;
  }

  // Release Data: (releaseHash => value)
  mapping (bytes32 => Release) _recordedReleases;
  IndexedOrderedSetLib.IndexedOrderedSet _allReleaseHashes;
  mapping (bytes32 => IndexedOrderedSetLib.IndexedOrderedSet) _releaseHashesByNameHash;

  // Version Data: (versionHash => value)
  mapping (bytes32 => SemVersionLib.SemVersion) _recordedVersions;
  mapping (bytes32 => bool) _versionExists;

  // Events
  event ReleaseCreate(bytes32 indexed releaseHash);
  event ReleaseUpdate(bytes32 indexed releaseHash);
  event ReleaseDelete(bytes32 indexed releaseHash, string reason);

  /*
   * Latest released version tracking for each branch of the release tree.
   */
  // (nameHash => releaseHash);
  mapping (bytes32 => bytes32) _latestMajor;

  // (nameHash => major => releaseHash);
  mapping (bytes32 => mapping(uint32 => bytes32)) _latestMinor;

  // (nameHash => major => minor => releaseHash);
  mapping (bytes32 => mapping (uint32 => mapping(uint32 => bytes32))) _latestPatch;

  // (nameHash => major => minor => patch => releaseHash);
  mapping (bytes32 => mapping (uint32 => mapping(uint32 => mapping (uint32 => bytes32)))) _latestPreRelease;

  /*
   *  Modifiers
   */
  modifier onlyIfVersionExists(bytes32 versionHash) {
    if (versionExists(versionHash)) {
      _;
    } else {
      throw;
    }
  }

  modifier onlyIfReleaseExists(bytes32 releaseHash) {
    if (releaseExists(releaseHash)) {
      _;
    } else {
      throw;
    }
  }

  //
  // +-------------+
  // |  Write API  |
  // +-------------+
  //

  /// @dev Creates or updates a release for a package.  Returns success.
  /// @param nameHash The name hash of the package.
  /// @param versionHash The version hash for the release version.
  /// @param releaseLockfileURI The URI for the release lockfile for this release.
  function setRelease(bytes32 nameHash,
                      bytes32 versionHash,
                      string releaseLockfileURI) public auth returns (bool) {
    bytes32 releaseHash = hashRelease(nameHash, versionHash);

    var release = _recordedReleases[releaseHash];

    // If this is a new version push it onto the array of version hashes for
    // this package.
    if (release.exists) {
      ReleaseUpdate(releaseHash);
    } else {
      // Populate the basic rlease data.
      release.exists = true;
      release.createdAt = now;
      release.nameHash = nameHash;
      release.versionHash = versionHash;

      // Push the release hash into the array of all release hashes.
      _allReleaseHashes.add(releaseHash);
      _releaseHashesByNameHash[nameHash].add(releaseHash);

      ReleaseCreate(releaseHash);
    }

    // Record the last time the release was updated.
    release.updatedAt = now;

    // Save the release lockfile URI
    release.releaseLockfileURI = releaseLockfileURI;

    // Track latest released versions for each branch of the release tree.
    updateLatestTree(releaseHash);

    return true;
  }

  /// @dev Removes a release from a package.  Returns success.
  /// @param releaseHash The release hash to be removed
  /// @param reason Explanation for why the removal happened.
  function removeRelease(bytes32 releaseHash, string reason) public
                                                             auth
                                                             onlyIfReleaseExists(releaseHash) 
                                                             returns (bool) {
    var (nameHash, versionHash,) = getReleaseData(releaseHash);
    var (major, minor, patch) = getMajorMinorPatch(versionHash);

    // In any branch of the release tree in which this version is the latest we
    // remove it.  This will leave the release tree for this package in an
    // invalid state.  The `updateLatestTree` function` provides a path to
    // recover from this state.  The naive approach would be to call it on all
    // release hashes in the array of remaining package release hashes which
    // will properly repopulate the release tree for this package.
    if (isLatestMajorTree(nameHash, versionHash)) {
      delete _latestMajor[nameHash];
    }
    if (isLatestMinorTree(nameHash, versionHash)) {
      delete _latestMinor[nameHash][major];
    }
    if (isLatestPatchTree(nameHash, versionHash)) {
      delete _latestPatch[nameHash][major][minor];
    }
    if (isLatestPreReleaseTree(nameHash, versionHash)) {
      delete _latestPreRelease[nameHash][major][minor][patch];
    }

    // Zero out the release data.
    delete _recordedReleases[releaseHash];

    // Remove the release hash from the list of all release hashes
    _allReleaseHashes.remove(releaseHash);
    _releaseHashesByNameHash[nameHash].remove(releaseHash);

    // Log the removal.
    ReleaseDelete(releaseHash, reason);

    return true;
  }

  /// @dev Updates each branch of the tree, replacing the current leaf node with this release hash if this release hash should be the new leaf.  Returns success.
  /// @param releaseHash The releaseHash to check.
  function updateLatestTree(bytes32 releaseHash) public auth returns (bool) {
    updateMajorTree(releaseHash);
    updateMinorTree(releaseHash);
    updatePatchTree(releaseHash);
    updatePreReleaseTree(releaseHash);
    return true;
  }

  /// @dev Adds the given version to the local version database.  Returns the versionHash for the provided version.
  /// @param major The major portion of the semver version string.
  /// @param minor The minor portion of the semver version string.
  /// @param patch The patch portion of the semver version string.
  /// @param preRelease The pre-release portion of the semver version string.  Use empty string if the version string has no pre-release portion.
  /// @param build The build portion of the semver version string.  Use empty string if the version string has no build portion.
  function setVersion(uint32 major,
                      uint32 minor,
                      uint32 patch,
                      string preRelease,
                      string build) public auth returns (bytes32) {
    bytes32 versionHash = hashVersion(major, minor, patch, preRelease, build);

    if (!_versionExists[versionHash]) {
      _recordedVersions[versionHash].init(major, minor, patch, preRelease, build);
      _versionExists[versionHash] = true;
    }
    return versionHash;
  }

  //
  // +------------+
  // |  Read API  |
  // +------------+
  //

  /// @dev Get the total number of releases
  function getNumReleases() constant returns (uint) {
    return _allReleaseHashes.size();
  }

  /// @dev Get the total number of releases
  /// @param idx The index of the release hash to retrieve.
  function getReleaseHash(uint idx) constant returns (bytes32) {
    return _allReleaseHashes.get(idx);
  }

  /// @dev Get the total number of releases
  /// @param nameHash the name hash to lookup.
  function getNumReleasesForNameHash(bytes32 nameHash) constant returns (uint) {
    return _releaseHashesByNameHash[nameHash].size();
  }

  /// @dev Get the total number of releases
  /// @param nameHash the name hash to lookup.
  /// @param idx The index of the release hash to retrieve.
  function getReleaseHashForNameHash(bytes32 nameHash, uint idx) constant returns (bytes32) {
    return _releaseHashesByNameHash[nameHash].get(idx);
  }

  /// @dev Query the existence of a release at the provided version for a package.  Returns boolean indicating whether such a release exists.
  /// @param releaseHash The release hash to query.
  function releaseExists(bytes32 releaseHash) constant returns (bool) {
    return _recordedReleases[releaseHash].exists;
  }

  /// @dev Query the existence of the provided version in the recorded versions.  Returns boolean indicating whether such a version exists.
  /// @param versionHash the version hash to check.
  function versionExists(bytes32 versionHash) constant returns (bool) {
    return _versionExists[versionHash];
  }

  /// @dev Returns the releaseHash at the given index for a package.
  /// @param releaseHash The release hash.
  function getReleaseData(bytes32 releaseHash) onlyIfReleaseExists(releaseHash)
                                               constant 
                                               returns (bytes32 nameHash,
                                                        bytes32 versionHash,
                                                        uint createdAt,
                                                        uint updatedAt) {
    var release = _recordedReleases[releaseHash];
    return (release.nameHash, release.versionHash, release.createdAt, release.updatedAt);
  }

  /// @dev Returns a 3-tuple of the major, minor, and patch components from the version of the given release hash.
  /// @param versionHash the version hash
  function getMajorMinorPatch(bytes32 versionHash) onlyIfVersionExists(versionHash) 
                                                   constant 
                                                   returns (uint32, uint32, uint32) {
    var version = _recordedVersions[versionHash];
    return (version.major, version.minor, version.patch);
  }

  /// @dev Returns the pre-release string from the version of the given release hash.
  /// @param releaseHash Release hash
  function getPreRelease(bytes32 releaseHash) onlyIfReleaseExists(releaseHash) 
                                              constant 
                                              returns (string) {
    return _recordedVersions[_recordedReleases[releaseHash].versionHash].preRelease;
  }

  /// @dev Returns the build string from the version of the given release hash.
  /// @param releaseHash Release hash
  function getBuild(bytes32 releaseHash) onlyIfReleaseExists(releaseHash) 
                                         constant 
                                         returns (string) {
    return _recordedVersions[_recordedReleases[releaseHash].versionHash].build;
  }

  /// @dev Returns the URI of the release lockfile for the given release hash.
  /// @param releaseHash Release hash
  function getReleaseLockfileURI(bytes32 releaseHash) onlyIfReleaseExists(releaseHash)
                                                      constant 
                                                      returns (string) {
    return _recordedReleases[releaseHash].releaseLockfileURI;
  }

  /*
   *  Hash Functions
   */
  /// @dev Returns version hash for the given semver version.
  /// @param major The major portion of the semver version string.
  /// @param minor The minor portion of the semver version string.
  /// @param patch The patch portion of the semver version string.
  /// @param preRelease The pre-release portion of the semver version string.  Use empty string if the version string has no pre-release portion.
  /// @param build The build portion of the semver version string.  Use empty string if the version string has no build portion.
  function hashVersion(uint32 major,
                       uint32 minor,
                       uint32 patch,
                       string preRelease,
                       string build) constant returns (bytes32) {
    return sha3(major, minor, patch, preRelease, build);
  }

  /// @dev Returns release hash for the given release
  /// @param nameHash The name hash of the package name.
  /// @param versionHash The version hash for the release version.
  function hashRelease(bytes32 nameHash,
                       bytes32 versionHash) constant returns (bytes32) {
    return sha3(nameHash, versionHash);
  }

  /*
   *  Latest version querying API
   */

  /// @dev Returns the release hash of the latest release in the major branch of the package release tree.
  /// @param nameHash The nameHash of the package
  function getLatestMajorTree(bytes32 nameHash) constant returns (bytes32) {
    return _latestMajor[nameHash];
  }

  /// @dev Returns the release hash of the latest release in the minor branch of the package release tree.
  /// @param nameHash The nameHash of the package
  /// @param major The branch of the major portion of the release tree to check.
  function getLatestMinorTree(bytes32 nameHash, uint32 major) constant returns (bytes32) {
    return _latestMinor[nameHash][major];
  }

  /// @dev Returns the release hash of the latest release in the patch branch of the package release tree.
  /// @param nameHash The nameHash of the package
  /// @param major The branch of the major portion of the release tree to check.
  /// @param minor The branch of the minor portion of the release tree to check.
  function getLatestPatchTree(bytes32 nameHash,
                              uint32 major,
                              uint32 minor) constant returns (bytes32) {
    return _latestPatch[nameHash][major][minor];
  }

  /// @dev Returns the release hash of the latest release in the pre-release branch of the package release tree.
  /// @param nameHash The nameHash of the package
  /// @param major The branch of the major portion of the release tree to check.
  /// @param minor The branch of the minor portion of the release tree to check.
  /// @param patch The branch of the patch portion of the release tree to check.
  function getLatestPreReleaseTree(bytes32 nameHash,
                                   uint32 major,
                                   uint32 minor,
                                   uint32 patch) constant returns (bytes32) {
    return _latestPreRelease[nameHash][major][minor][patch];
  }

  /// @dev Returns boolean indicating whethe the given version hash is the latest version in the major branch of the release tree.
  /// @param nameHash The nameHash of the package to check against.
  /// @param versionHash The versionHash of the version to check.
  function isLatestMajorTree(bytes32 nameHash,
                             bytes32 versionHash) onlyIfVersionExists(versionHash) 
                                                  constant 
                                                  returns (bool) {
    var version = _recordedVersions[versionHash];
    var latestMajor = _recordedVersions[_recordedReleases[getLatestMajorTree(nameHash)].versionHash];
    return version.isGreaterOrEqual(latestMajor);
  }

  /// @dev Returns boolean indicating whethe the given version hash is the latest version in the minor branch of the release tree.
  /// @param nameHash The nameHash of the package to check against.
  /// @param versionHash The versionHash of the version to check.
  function isLatestMinorTree(bytes32 nameHash,
                             bytes32 versionHash) onlyIfVersionExists(versionHash) 
                                                  constant 
                                                  returns (bool) {
    var version = _recordedVersions[versionHash];
    var latestMinor = _recordedVersions[_recordedReleases[getLatestMinorTree(nameHash, version.major)].versionHash];
    return version.isGreaterOrEqual(latestMinor);
  }

  /// @dev Returns boolean indicating whethe the given version hash is the latest version in the patch branch of the release tree.
  /// @param nameHash The nameHash of the package to check against.
  /// @param versionHash The versionHash of the version to check.
  function isLatestPatchTree(bytes32 nameHash,
                             bytes32 versionHash) onlyIfVersionExists(versionHash) 
                                                  constant 
                                                  returns (bool) {
    var version = _recordedVersions[versionHash];
    var latestPatch = _recordedVersions[_recordedReleases[getLatestPatchTree(nameHash, version.major, version.minor)].versionHash];
    return version.isGreaterOrEqual(latestPatch);
  }

  /// @dev Returns boolean indicating whethe the given version hash is the latest version in the pre-release branch of the release tree.
  /// @param nameHash The nameHash of the package to check against.
  /// @param versionHash The versionHash of the version to check.
  function isLatestPreReleaseTree(bytes32 nameHash,
                                  bytes32 versionHash) onlyIfVersionExists(versionHash) 
                                                       constant 
                                                       returns (bool) {
    var version = _recordedVersions[versionHash];
    var latestPreRelease = _recordedVersions[_recordedReleases[getLatestPreReleaseTree(nameHash, version.major, version.minor, version.patch)].versionHash];
    return version.isGreaterOrEqual(latestPreRelease);
  }

  //
  // +----------------+
  // |  Internal API  |
  // +----------------+
  //

  /*
   *  Tracking of latest releases for each branch of the release tree.
   */

  /// @dev Sets the given release as the new leaf of the major branch of the release tree if it is greater or equal to the current leaf.
  /// @param releaseHash The release hash of the release to check.
  function updateMajorTree(bytes32 releaseHash) onlyIfReleaseExists(releaseHash) 
                                                internal 
                                                returns (bool) {
    var (nameHash, versionHash,) = getReleaseData(releaseHash);

    if (isLatestMajorTree(nameHash, versionHash)) {
      _latestMajor[nameHash] = releaseHash;
      return true;
    } else {
      return false;
    }
  }

  /// @dev Sets the given release as the new leaf of the minor branch of the release tree if it is greater or equal to the current leaf.
  /// @param releaseHash The release hash of the release to check.
  function updateMinorTree(bytes32 releaseHash) internal returns (bool) {
    var (nameHash, versionHash,) = getReleaseData(releaseHash);

    if (isLatestMinorTree(nameHash, versionHash)) {
      var (major,) = getMajorMinorPatch(versionHash);
      _latestMinor[nameHash][major] = releaseHash;
      return true;
    } else {
      return false;
    }
  }

  /// @dev Sets the given release as the new leaf of the patch branch of the release tree if it is greater or equal to the current leaf.
  /// @param releaseHash The release hash of the release to check.
  function updatePatchTree(bytes32 releaseHash) internal returns (bool) {
    var (nameHash, versionHash,) = getReleaseData(releaseHash);

    if (isLatestPatchTree(nameHash, versionHash)) {
      var (major, minor,) = getMajorMinorPatch(versionHash);
      _latestPatch[nameHash][major][minor] = releaseHash;
      return true;
    } else {
      return false;
    }
  }

  /// @dev Sets the given release as the new leaf of the pre-release branch of the release tree if it is greater or equal to the current leaf.
  /// @param releaseHash The release hash of the release to check.
  function updatePreReleaseTree(bytes32 releaseHash) internal returns (bool) {
    var (nameHash, versionHash,) = getReleaseData(releaseHash);

    if (isLatestPreReleaseTree(nameHash, versionHash)) {
      var (major, minor, patch) = getMajorMinorPatch(versionHash);
      _latestPreRelease[nameHash][major][minor][patch] = releaseHash;
      return true;
    } else {
      return false;
    }
  }
}
contract ReleaseValidator {
  /// @dev Runs validation on all of the data needed for releasing a package.  Returns success.
  /// @param packageDb The address of the PackageDB
  /// @param releaseDb The address of the ReleaseDB
  /// @param callerAddress The address which is attempting to create the release.
  /// @param name The name of the package.
  /// @param majorMinorPatch The major/minor/patch portion of the version string.
  /// @param preRelease The pre-release portion of the version string.
  /// @param build The build portion of the version string.
  /// @param releaseLockfileURI The URI of the release lockfile.
  function validateRelease(PackageDB packageDb,
                           ReleaseDB releaseDb,
                           address callerAddress,
                           string name,
                           uint32[3] majorMinorPatch,
                           string preRelease,
                           string build,
                           string releaseLockfileURI) constant returns (bool) {
    if (address(packageDb) == 0x0 || address(releaseDb) == 0x0) throw;

    if (!validateAuthorization(packageDb, callerAddress, name)) {
      // package exists and msg.sender is not the owner not the package owner.
      return false;
    } else if (!validateIsNewRelease(packageDb, releaseDb, name, majorMinorPatch, preRelease, build)) {
      // this version has already been released.
      return false;
    } else if (!validatePackageName(packageDb, name)) {
      // invalid package name.
      return false;
    } else if (!validateReleaseLockfileURI(releaseLockfileURI)) {
      // disallow empty release lockfile URI
      return false;
    } else if (!validateReleaseVersion(majorMinorPatch)) {
      // disallow version 0.0.0
      return false;
    } else if (!validateIsAnyLatest(packageDb, releaseDb, name, majorMinorPatch, preRelease, build)) {
      // Only allow releasing of versions which are the latest in their
      // respective branch of the release tree.
      return false;
    }
    return true;
  }

  /// @dev Validate whether the callerAddress is authorized to make this release.
  /// @param packageDb The address of the PackageDB
  /// @param callerAddress The address which is attempting to create the release.
  /// @param name The name of the package.
  function validateAuthorization(PackageDB packageDb,
                                 address callerAddress,
                                 string name) constant returns (bool) {
    bytes32 nameHash = packageDb.hashName(name);
    if (!packageDb.packageExists(nameHash)) {
      return true;
    }
    var (packageOwner,) = packageDb.getPackageData(nameHash);
    if (packageOwner == callerAddress) {
      return true;
    }
    return false;
  }

  /// @dev Validate that the version being released has not already been released.
  /// @param packageDb The address of the PackageDB
  /// @param releaseDb The address of the ReleaseDB
  /// @param name The name of the package.
  /// @param majorMinorPatch The major/minor/patch portion of the version string.
  /// @param preRelease The pre-release portion of the version string.
  /// @param build The build portion of the version string.
  function validateIsNewRelease(PackageDB packageDb,
                                ReleaseDB releaseDb,
                                string name,
                                uint32[3] majorMinorPatch,
                                string preRelease,
                                string build) constant returns (bool) {
    var nameHash = packageDb.hashName(name);
    var versionHash = releaseDb.hashVersion(majorMinorPatch[0], majorMinorPatch[1], majorMinorPatch[2], preRelease, build);
    var releaseHash = releaseDb.hashRelease(nameHash, versionHash);
    return !releaseDb.releaseExists(releaseHash);
  }

  uint constant DIGIT_0 = uint(bytes1('0'));
  uint constant DIGIT_9 = uint(bytes1('9'));
  uint constant LETTER_a = uint(bytes1('a'));
  uint constant LETTER_z = uint(bytes1('z'));
  bytes1 constant DASH = bytes1('-');

  /// @dev Returns boolean whether the provided package name is valid.
  /// @param packageDb The address of the PackageDB
  /// @param name The name of the package.
  function validatePackageName(PackageDB packageDb, string name) constant returns (bool) {
    var nameHash = packageDb.hashName(name);

    if (packageDb.packageExists(nameHash)) {
      // existing names are always valid.
      return true;
    }

    if (bytes(name).length < 2 || bytes(name).length > 214) {
      return false;
    }
    for (uint i=0; i < bytes(name).length; i++) {
      if (bytes(name)[i] == DASH && i > 0) {
        continue;
      } else if (i > 0 && uint(bytes(name)[i]) >= DIGIT_0 && uint(bytes(name)[i]) <= DIGIT_9) {
        continue;
      } else if (uint(bytes(name)[i]) >= LETTER_a && uint(bytes(name)[i]) <= LETTER_z) {
        continue;
      } else {
        return false;
      }
    }
    return true;
  }

  /// @dev Returns boolean whether the provided release lockfile URI is valid.
  /// @param releaseLockfileURI The URI for a release lockfile.
  function validateReleaseLockfileURI(string releaseLockfileURI) constant returns (bool) {
    if (bytes(releaseLockfileURI).length ==0) {
      return false;
    }
    return true;
  }

  /// @dev Validate that the version is not 0.0.0.
  /// @param majorMinorPatch The major/minor/patch portion of the version string.
  function validateReleaseVersion(uint32[3] majorMinorPatch) constant returns (bool) {
    if (majorMinorPatch[0] > 0) {
      return true;
    } else if (majorMinorPatch[1] > 0) {
      return true;
    } else if (majorMinorPatch[2] > 0) {
      return true;
    } else {
      return false;
    }
  }

  /// @dev Validate that the version being released is the latest in at least one branch of the release tree.
  /// @param packageDb The address of the PackageDB
  /// @param releaseDb The address of the ReleaseDB
  /// @param name The name of the package.
  /// @param majorMinorPatch The major/minor/patch portion of the version string.
  /// @param preRelease The pre-release portion of the version string.
  /// @param build The build portion of the version string.
  function validateIsAnyLatest(PackageDB packageDb,
                               ReleaseDB releaseDb,
                               string name,
                               uint32[3] majorMinorPatch,
                               string preRelease,
                               string build) constant returns (bool) {
    var nameHash = packageDb.hashName(name);
    var versionHash = releaseDb.hashVersion(majorMinorPatch[0], majorMinorPatch[1], majorMinorPatch[2], preRelease, build);
    if (releaseDb.isLatestMajorTree(nameHash, versionHash)) {
      return true;
    } else if (hasLatestMinor(releaseDb, nameHash, versionHash) && releaseDb.isLatestMinorTree(nameHash, versionHash)) {
      return true;
    } else if (hasLatestPatch(releaseDb, nameHash, versionHash) && releaseDb.isLatestPatchTree(nameHash, versionHash)) {
      return true;
    } else if (hasLatestPreRelease(releaseDb, nameHash, versionHash) && releaseDb.isLatestPreReleaseTree(nameHash, versionHash)) {
      return true;
    } else {
      return false;
    }
  }

  /// @dev Returns boolean indicating whether there is a latest minor version in the version tree indicated by the provided version has for the package indicated by the provided name hash.
  /// @param releaseDb The address of the ReleaseDB
  /// @param nameHash The nameHash of the package to check against.
  /// @param versionHash The versionHash of the version to check.
  function hasLatestMinor(ReleaseDB releaseDb, bytes32 nameHash, bytes32 versionHash) constant returns (bool) {
    var (major,) = releaseDb.getMajorMinorPatch(versionHash);
    return releaseDb.getLatestMinorTree(nameHash, major) != 0x0;
  }

  /// @dev Returns boolean indicating whether there is a latest patch version in the version tree indicated by the provided version has for the package indicated by the provided name hash.
  /// @param releaseDb The address of the ReleaseDB
  /// @param nameHash The nameHash of the package to check against.
  /// @param versionHash The versionHash of the version to check.
  function hasLatestPatch(ReleaseDB releaseDb, bytes32 nameHash, bytes32 versionHash) constant returns (bool) {
    var (major, minor,) = releaseDb.getMajorMinorPatch(versionHash);
    return releaseDb.getLatestPatchTree(nameHash, major, minor) != 0x0;
  }

  /// @dev Returns boolean indicating whether there is a latest pre-release version in the version tree indicated by the provided version has for the package indicated by the provided name hash.
  /// @param releaseDb The address of the ReleaseDB
  /// @param nameHash The nameHash of the package to check against.
  /// @param versionHash The versionHash of the version to check.
  function hasLatestPreRelease(ReleaseDB releaseDb, bytes32 nameHash, bytes32 versionHash) constant returns (bool) {
    var (major, minor, patch) = releaseDb.getMajorMinorPatch(versionHash);
    return releaseDb.getLatestPreReleaseTree(nameHash, major, minor, patch) != 0x0;
  }
}
/// @title Database contract for a package index.
/// @author Tim Coulter <tim.coulter@consensys.net>, Piper Merriam <pipermerriam@gmail.com>
contract PackageIndexInterface is AuthorizedInterface {
  //
  // Events
  //
  event PackageRelease(bytes32 indexed nameHash, bytes32 indexed releaseHash);
  event PackageTransfer(address indexed oldOwner, address indexed newOwner);

  //
  // Administrative API
  //
  /// @dev Sets the address of the PackageDb contract.
  /// @param newPackageDb The address to set for the PackageDb.
  function setPackageDb(address newPackageDb) public auth returns (bool);

  /// @dev Sets the address of the ReleaseDb contract.
  /// @param newReleaseDb The address to set for the ReleaseDb.
  function setReleaseDb(address newReleaseDb) public auth returns (bool);

  /// @dev Sets the address of the ReleaseValidator contract.
  /// @param newReleaseValidator The address to set for the ReleaseValidator.
  function setReleaseValidator(address newReleaseValidator) public auth returns (bool);

  //
  // +-------------+
  // |  Write API  |
  // +-------------+
  //
  /// @dev Creates a a new release for the named package.  If this is the first release for the given package then this will also assign msg.sender as the owner of the package.  Returns success.
  /// @notice Will create a new release the given package with the given release information.
  /// @param name Package name
  /// @param major The major portion of the semver version string.
  /// @param minor The minor portion of the semver version string.
  /// @param patch The patch portion of the semver version string.
  /// @param preRelease The pre-release portion of the semver version string.  Use empty string if the version string has no pre-release portion.
  /// @param build The build portion of the semver version string.  Use empty string if the version string has no build portion.
  /// @param releaseLockfileURI The URI for the release lockfile for this release.
  function release(string name,
                   uint32 major,
                   uint32 minor,
                   uint32 patch,
                   string preRelease,
                   string build,
                   string releaseLockfileURI) public auth returns (bool);

  /// @dev Transfers package ownership to the provider new owner address.
  /// @notice Will transfer ownership of this package to the provided new owner address.
  /// @param name Package name
  /// @param newPackageOwner The address of the new owner.
  function transferPackageOwner(string name,
                                address newPackageOwner) public auth returns (bool);

  //
  // +------------+
  // |  Read API  |
  // +------------+
  //

  /// @dev Returns the address of the packageDb
  function getPackageDb() constant returns (address);

  /// @dev Returns the address of the releaseDb
  function getReleaseDb() constant returns (address);

  /// @dev Returns the address of the releaseValidator
  function getReleaseValidator() constant returns (address);

  /// @dev Query the existence of a package with the given name.  Returns boolean indicating whether the package exists.
  /// @param name Package name
  function packageExists(string name) constant returns (bool);

  /// @dev Query the existence of a release at the provided version for the named package.  Returns boolean indicating whether such a release exists.
  /// @param name Package name
  /// @param major The major portion of the semver version string.
  /// @param minor The minor portion of the semver version string.
  /// @param patch The patch portion of the semver version string.
  /// @param preRelease The pre-release portion of the semver version string.  Use empty string if the version string has no pre-release portion.
  /// @param build The build portion of the semver version string.  Use empty string if the version string has no build portion.
  function releaseExists(string name,
                         uint32 major,
                         uint32 minor,
                         uint32 patch,
                         string preRelease,
                         string build) constant returns (bool);

  /// @dev Returns the number of packages in the index
  function getNumPackages() constant returns (uint);

  /// @dev Returns the name of the package at the provided index
  /// @param idx The index of the name hash to lookup.
  function getPackageName(uint idx) constant returns (string);

  /// @dev Returns the package data.
  /// @param name Package name
  function getPackageData(string name) constant
                                       returns (address packageOwner,
                                                uint createdAt,
                                                uint numReleases,
                                                uint updatedAt);

  /// @dev Returns the release data for the release associated with the given release hash.
  /// @param releaseHash The release hash.
  function getReleaseData(bytes32 releaseHash) constant returns (uint32 major,
                                                                 uint32 minor,
                                                                 uint32 patch,
                                                                 string preRelease,
                                                                 string build,
                                                                 string releaseLockfileURI,
                                                                 uint createdAt,
                                                                 uint updatedAt);

  /// @dev Returns the release hash at the provide index in the array of all release hashes.
  /// @param idx The index of the release to retrieve.
  function getReleaseHash(uint idx) constant returns (bytes32);

  /// @dev Returns the release hash at the provide index in the array of release hashes for the given package.
  /// @param name Package name
  /// @param releaseIdx The index of the release to retrieve.
  function getReleaseHashForPackage(string name,
                                    uint releaseIdx) constant returns (bytes32);

  /// @dev Returns an array of all release hashes for the named package.
  /// @param name Package name
  function getAllPackageReleaseHashes(string name) constant returns (bytes32[]);

  /// @dev Returns a slice of the array of all release hashes for the named package.
  /// @param name Package name
  /// @param offset The starting index for the slice.
  /// @param numReleases The length of the slice
  function getPackageReleaseHashes(string name,
                                   uint offset,
                                   uint numReleases) constant returns (bytes32[]);

  function getNumReleases() constant returns (uint);

  /// @dev Returns an array of all release hashes for the named package.
  function getAllReleaseHashes() constant returns (bytes32[]);

  /// @dev Returns a slice of the array of all release hashes for the named package.
  /// @param offset The starting index for the slice.
  /// @param numReleases The length of the slice
  function getReleaseHashes(uint offset, uint numReleases) constant returns (bytes32[]);

  /// @dev Returns the release lockfile for the given release data
  /// @param name Package name
  /// @param major The major portion of the semver version string.
  /// @param minor The minor portion of the semver version string.
  /// @param patch The patch portion of the semver version string.
  /// @param preRelease The pre-release portion of the semver version string.  Use empty string if the version string has no pre-release portion.
  /// @param build The build portion of the semver version string.  Use empty string if the version string has no build portion.
  function getReleaseLockfileURI(string name,
                                uint32 major,
                                uint32 minor,
                                uint32 patch,
                                string preRelease,
                                string build) constant returns (string);
}
/// @title Database contract for a package index.
/// @author Tim Coulter <tim.coulter@consensys.net>, Piper Merriam <pipermerriam@gmail.com>
contract PackageIndex is Authorized, PackageIndexInterface {
  PackageDB private packageDb;
  ReleaseDB private releaseDb;
  ReleaseValidator private releaseValidator;

  //
  // Administrative API
  //
  /// @dev Sets the address of the PackageDb contract.
  /// @param newPackageDb The address to set for the PackageDb.
  function setPackageDb(address newPackageDb) public auth returns (bool) {
    packageDb = PackageDB(newPackageDb);
    return true;
  }

  /// @dev Sets the address of the ReleaseDb contract.
  /// @param newReleaseDb The address to set for the ReleaseDb.
  function setReleaseDb(address newReleaseDb) public auth returns (bool) {
    releaseDb = ReleaseDB(newReleaseDb);
    return true;
  }

  /// @dev Sets the address of the ReleaseValidator contract.
  /// @param newReleaseValidator The address to set for the ReleaseValidator.
  function setReleaseValidator(address newReleaseValidator) public auth returns (bool) {
    releaseValidator = ReleaseValidator(newReleaseValidator);
    return true;
  }

  //
  // +-------------+
  // |  Write API  |
  // +-------------+
  //
  /// @dev Creates a a new release for the named package.  If this is the first release for the given package then this will also assign msg.sender as the owner of the package.  Returns success.
  /// @notice Will create a new release the given package with the given release information.
  /// @param name Package name
  /// @param major The major portion of the semver version string.
  /// @param minor The minor portion of the semver version string.
  /// @param patch The patch portion of the semver version string.
  /// @param preRelease The pre-release portion of the semver version string.  Use empty string if the version string has no pre-release portion.
  /// @param build The build portion of the semver version string.  Use empty string if the version string has no build portion.
  /// @param releaseLockfileURI The URI for the release lockfile for this release.
  function release(string name,
                   uint32 major,
                   uint32 minor,
                   uint32 patch,
                   string preRelease,
                   string build,
                   string releaseLockfileURI) public auth returns (bool) {
    if (address(packageDb) == 0x0 || address(releaseDb) == 0x0 || address(releaseValidator) == 0x0) throw;
    return release(name, [major, minor, patch], preRelease, build, releaseLockfileURI);
  }

  /// @dev Creates a a new release for the named package.  If this is the first release for the given package then this will also assign msg.sender as the owner of the package.  Returns success.
  /// @notice Will create a new release the given package with the given release information.
  /// @param name Package name
  /// @param majorMinorPatch The major/minor/patch portion of the version string.
  /// @param preRelease The pre-release portion of the semver version string.  Use empty string if the version string has no pre-release portion.
  /// @param build The build portion of the semver version string.  Use empty string if the version string has no build portion.
  /// @param releaseLockfileURI The URI for the release lockfile for this release.
  function release(string name,
                   uint32[3] majorMinorPatch,
                   string preRelease,
                   string build,
                   string releaseLockfileURI) internal returns (bool) {
    bytes32 versionHash = releaseDb.hashVersion(majorMinorPatch[0], majorMinorPatch[1], majorMinorPatch[2], preRelease, build);

    // If the version for this release is not in the version database, populate
    // it.  This must happen prior to validation to ensure that the version is
    // present in the releaseDb.
    if (!releaseDb.versionExists(versionHash)) {
      releaseDb.setVersion(majorMinorPatch[0], majorMinorPatch[1], majorMinorPatch[2], preRelease, build);
    }

    if (!releaseValidator.validateRelease(packageDb, releaseDb, msg.sender, name, majorMinorPatch, preRelease, build, releaseLockfileURI)) {
      // Release is invalid
      return false;
    }

    // Compute hashes
    bool _packageExists = packageExists(name);

    // Both creates the package if it is new as well as updating the updatedAt
    // timestamp on the package.
    packageDb.setPackage(name);

    bytes32 nameHash = packageDb.hashName(name);

    // If the package does not yet exist create it and set the owner
    if (!_packageExists) {
      packageDb.setPackageOwner(nameHash, msg.sender);
    }

    // Create the release and add it to the list of package release hashes.
    releaseDb.setRelease(nameHash, versionHash, releaseLockfileURI);

    // Log the release.
    PackageRelease(nameHash, releaseDb.hashRelease(nameHash, versionHash));

    return true;
  }

  /// @dev Transfers package ownership to the provider new owner address.
  /// @notice Will transfer ownership of this package to the provided new owner address.
  /// @param name Package name
  /// @param newPackageOwner The address of the new owner.
  function transferPackageOwner(string name,
                                address newPackageOwner) public auth returns (bool) {
    if (isPackageOwner(name, msg.sender)) {
      // Only the package owner may transfer package ownership.
      return false;
    }

    // Lookup the current owne
    var (packageOwner,) = getPackageData(name);

    // Log the transfer
    PackageTransfer(packageOwner, newPackageOwner);

    // Update the owner.
    packageDb.setPackageOwner(packageDb.hashName(name), newPackageOwner);

    return true;
  }

  //
  // +------------+
  // |  Read API  |
  // +------------+
  //

  /// @dev Returns the address of the packageDb
  function getPackageDb() constant returns (address) {
    return address(packageDb);
  }

  /// @dev Returns the address of the releaseDb
  function getReleaseDb() constant returns (address) {
    return address(releaseDb);
  }

  /// @dev Returns the address of the releaseValidator
  function getReleaseValidator() constant returns (address) {
    return address(releaseValidator);
  }

  /// @dev Query the existence of a package with the given name.  Returns boolean indicating whether the package exists.
  /// @param name Package name
  function packageExists(string name) constant returns (bool) {
    return packageDb.packageExists(packageDb.hashName(name));
  }

  /// @dev Query the existence of a release at the provided version for the named package.  Returns boolean indicating whether such a release exists.
  /// @param name Package name
  /// @param major The major portion of the semver version string.
  /// @param minor The minor portion of the semver version string.
  /// @param patch The patch portion of the semver version string.
  /// @param preRelease The pre-release portion of the semver version string.  Use empty string if the version string has no pre-release portion.
  /// @param build The build portion of the semver version string.  Use empty string if the version string has no build portion.
  function releaseExists(string name,
                         uint32 major,
                         uint32 minor,
                         uint32 patch,
                         string preRelease,
                         string build) constant returns (bool) {
    var nameHash = packageDb.hashName(name);
    var versionHash = releaseDb.hashVersion(major, minor, patch, preRelease, build);
    return releaseDb.releaseExists(releaseDb.hashRelease(nameHash, versionHash));
  }

  /// @dev Returns the number of packages in the index
  function getNumPackages() constant returns (uint) {
    return packageDb.getNumPackages();
  }

  /// @dev Returns the name of the package at the provided index
  /// @param idx The index of the name hash to lookup.
  function getPackageName(uint idx) constant returns (string) {
    return getPackageName(packageDb.getPackageNameHash(idx));
  }

  /// @dev Returns the package data.
  /// @param name Package name
  function getPackageData(string name) constant
                                       returns (address packageOwner,
                                                uint createdAt,
                                                uint numReleases,
                                                uint updatedAt) {
    var nameHash = packageDb.hashName(name);
    (packageOwner, createdAt, updatedAt) = packageDb.getPackageData(nameHash);
    numReleases = releaseDb.getNumReleasesForNameHash(nameHash);
    return (packageOwner, createdAt, numReleases, updatedAt);
  }

  /// @dev Returns the release data for the release associated with the given release hash.
  /// @param releaseHash The release hash.
  function getReleaseData(bytes32 releaseHash) constant returns (uint32 major,
                                                                 uint32 minor,
                                                                 uint32 patch,
                                                                 string preRelease,
                                                                 string build,
                                                                 string releaseLockfileURI,
                                                                 uint createdAt,
                                                                 uint updatedAt) {
    bytes32 versionHash;
    (,versionHash, createdAt, updatedAt) = releaseDb.getReleaseData(releaseHash);
    (major, minor, patch) = releaseDb.getMajorMinorPatch(versionHash);
    preRelease = getPreRelease(releaseHash);
    build = getBuild(releaseHash);
    releaseLockfileURI = getReleaseLockfileURI(releaseHash);
    return (major, minor, patch, preRelease, build, releaseLockfileURI, createdAt, updatedAt);
  }

  /// @dev Returns the release hash at the provide index in the array of all release hashes.
  /// @param idx The index of the release to retrieve.
  function getReleaseHash(uint idx) constant returns (bytes32) {
    return releaseDb.getReleaseHash(idx);
  }

  /// @dev Returns the release hash at the provide index in the array of release hashes for the given package.
  /// @param name Package name
  /// @param releaseIdx The index of the release to retrieve.
  function getReleaseHashForPackage(string name,
                                    uint releaseIdx) constant returns (bytes32) {
    bytes32 nameHash = packageDb.hashName(name);
    return releaseDb.getReleaseHashForNameHash(nameHash, releaseIdx);
  }

  /// @dev Returns an array of all release hashes for the named package.
  /// @param name Package name
  function getAllPackageReleaseHashes(string name) constant returns (bytes32[]) {
    bytes32 nameHash = packageDb.hashName(name);
    var (,,numReleases,) = getPackageData(name);
    return getPackageReleaseHashes(name, 0, numReleases);
  }

  /// @dev Returns a slice of the array of all release hashes for the named package.
  /// @param name Package name
  /// @param offset The starting index for the slice.
  /// @param numReleases The length of the slice
  function getPackageReleaseHashes(string name, uint offset, uint numReleases) constant returns (bytes32[]) {
    bytes32 nameHash = packageDb.hashName(name);
    bytes32[] memory releaseHashes = new bytes32[](numReleases);

    for (uint i = offset; i < offset + numReleases; i++) {
      releaseHashes[i] = releaseDb.getReleaseHashForNameHash(nameHash, i);
    }

    return releaseHashes;
  }

  function getNumReleases() constant returns (uint) {
    return releaseDb.getNumReleases();
  }

  /// @dev Returns an array of all release hashes for the named package.
  function getAllReleaseHashes() constant returns (bytes32[]) {
    return getReleaseHashes(0, getNumReleases());
  }

  /// @dev Returns a slice of the array of all release hashes for the named package.
  /// @param offset The starting index for the slice.
  /// @param numReleases The length of the slice
  function getReleaseHashes(uint offset, uint numReleases) constant returns (bytes32[]) {
    bytes32[] memory releaseHashes = new bytes32[](numReleases);
    bytes32 buffer;

    for (uint i = offset; i < offset + numReleases; i++) {
      releaseHashes[i] = releaseDb.getReleaseHash(i);
    }

    return releaseHashes;
  }

  /// @dev Returns the release lockfile for the given release data
  /// @param name Package name
  /// @param major The major portion of the semver version string.
  /// @param minor The minor portion of the semver version string.
  /// @param patch The patch portion of the semver version string.
  /// @param preRelease The pre-release portion of the semver version string.  Use empty string if the version string has no pre-release portion.
  /// @param build The build portion of the semver version string.  Use empty string if the version string has no build portion.
  function getReleaseLockfileURI(string name,
                                uint32 major,
                                uint32 minor,
                                uint32 patch,
                                string preRelease,
                                string build) constant returns (string) {
    bytes32 versionHash = releaseDb.hashVersion(major, minor, patch, preRelease, build);
    bytes32 releaseHash = releaseDb.hashRelease(packageDb.hashName(name), versionHash);
    return getReleaseLockfileURI(releaseHash);
  }


  //
  // +----------------+
  // |  Internal API  |
  // +----------------+
  //
  /// @dev Returns boolean whether the provided address is the package owner
  /// @param name The name of the package
  /// @param _address The address to check
  function isPackageOwner(string name, address _address) internal returns (bool) {
    var (packageOwner,) = getPackageData(name);
    return (packageOwner != _address);
  }

  bytes4 constant GET_PACKAGE_NAME_SIG = bytes4(sha3("getPackageName(bytes32)"));

  /// @dev Retrieves the name for the given name hash.
  /// @param nameHash The name hash to lookup the name for.
  function getPackageName(bytes32 nameHash) internal returns (string) {
    return fetchString(address(packageDb), GET_PACKAGE_NAME_SIG, nameHash);
  }

  bytes4 constant GET_RELEASE_LOCKFILE_URI_SIG = bytes4(sha3("getReleaseLockfileURI(bytes32)"));

  /// @dev Retrieves the release lockfile URI from the package db.
  /// @param releaseHash The release hash to retrieve the URI from.
  function getReleaseLockfileURI(bytes32 releaseHash) internal returns (string) {
    return fetchString(address(releaseDb), GET_RELEASE_LOCKFILE_URI_SIG, releaseHash);
  }

  bytes4 constant GET_PRE_RELEASE_SIG = bytes4(sha3("getPreRelease(bytes32)"));

  /// @dev Retrieves the pre-release string from the package db.
  /// @param releaseHash The release hash to retrieve the string from.
  function getPreRelease(bytes32 releaseHash) internal returns (string) {
    return fetchString(address(releaseDb), GET_PRE_RELEASE_SIG, releaseHash);
  }

  bytes4 constant GET_BUILD_SIG = bytes4(sha3("getBuild(bytes32)"));

  /// @dev Retrieves the build string from the package db.
  /// @param releaseHash The release hash to retrieve the string from.
  function getBuild(bytes32 releaseHash) internal returns (string) {
    return fetchString(address(releaseDb), GET_BUILD_SIG, releaseHash);
  }

  /// @dev Retrieves a string from a function on the package db indicated by the provide function selector
  /// @param sig The 4-byte function selector to retrieve the signature from.
  /// @param arg The bytes32 argument that should be passed into the function.
  function fetchString(address codeAddress, bytes4 sig, bytes32 arg) internal constant returns (string s) {
    bool success;

    assembly {
      let m := mload(0x40) //Free memory pointer
      mstore(m,sig)
      mstore(add(m,4), arg) // Write arguments to memory- align directly after function sig.
      success := call( //Fetch string size
        sub(gas,8000), // g
        codeAddress,   // a
        0,             // v
        m,             // in
        0x24,          // insize: 4 byte sig + 32 byte uint
        add(m,0x24),   // Out pointer: don't overwrite the call data, we need it again
        0x40           // Only fetch the first 64 bytes of the string data.
      )
      let l := mload(add(m,0x44)) // returned data stats at 0x24, length is stored in the second 32-byte slot
      success :=  and(success,call(sub(gas,4000),codeAddress, 0,
        m, // Reuse the same argument data
        0x24,
        m,  // We can overwrite the calldata now to save space
        add(l, 0x40) // The length of the returned data will be 64 bytes of metadata + string length
      ))
      s := add(m, mload(m)) // First slot points to the start of the string (will almost always be m+0x20)
      mstore(0x40, add(m,add(l,0x40))) //Move free memory pointer so string doesn't get overwritten
    }
    if(!success) throw;

    return s;
  }
}
