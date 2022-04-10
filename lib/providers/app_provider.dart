import 'dart:async';
import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vocabify/data/dictapi.dart';
import 'package:vocabify/firebase_options.dart';
import '../screens/authentication.dart';
import '../data/vault.dart';
import '../screens/vault-view.dart';
import '../widgets/shared_vault.dart';
import '../widgets/user_vault.dart';

class AppProvider extends ChangeNotifier {

  ApplicationLoginState _loginState = ApplicationLoginState.emailAddress;
  ApplicationLoginState get loginState => _loginState;
  String? _email;
  String? get email => _email;
  String? _displayName;
  String? get name => _displayName;
  bool addFriend = false;

  StreamSubscription<QuerySnapshot>? _vaultItemSubscription;

  List<Widget> _vaultItems = [
    Stack(
      children: [
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(10.0),
            width: 30.0,
            height: 50.0,
            decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.all(Radius.circular(20))),
          ),
        ),
        const Positioned.fill(
          child: Icon(
            Icons.add_box,
            size: 100,
            color: Colors.white,
          ),
        ),
      ],
    )
  ];
  List<Widget> get vaultItems => _vaultItems;
  List<Vault> _vaults = [];
  List<Vault> get vaults => _vaults;
  User? currentUser;
  List<dynamic> currentFriends = [];

  List<Widget> sharedVaultItems = [];
  List<Vault> sharedVaults = [];

  //constructor
  AppProvider() {
    init();
    getFriendsList();
  }

  void initVaultItems() {
    _vaultItems = [];
    _vaultItems.add(Stack(
      children: [
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(10.0),
            width: 30.0,
            height: 50.0,
            decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.all(Radius.circular(20))),
          ),
        ),
        const Positioned.fill(
          child: Icon(
            Icons.add_box,
            size: 100,
            color: Colors.white,
          ),
        ),
      ],
    ));
    _vaultItems.addAll(sharedVaultItems);
  }

  Future<void> init() async {

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        currentUser = user;
        _loginState = ApplicationLoginState.loggedIn;
        _displayName = currentUser?.displayName;

        FirebaseFirestore.instance
          .collection('vaults')
          .where('sharedUsers', arrayContains: {"name": user.displayName, "uid": user.uid})
          .snapshots()
          .listen((snapshot){
            sharedVaultItems = [];
            sharedVaults = [];
            for (final document in snapshot.docs) {
              List<DictItem> items = (document['items'] as List<dynamic>).map((item) =>  
                  DictItem(word: item['word'], definitions: (item['definitions'] as List<dynamic>).map((e) => e.toString()).toList(),
                  synonyms: (item['synonyms'] as List<dynamic>).map((e) => e.toString()).toList())).toList();
              sharedVaults.add(Vault(uid:document['uid'] as String,name: document['name'] as String, vaultitems: items, fbusers: []));
              sharedVaultItems.add(SharedVault(name: document['name'] as String));
            }
          });

        FirebaseFirestore.instance
            .collection('vaults')
            .where('uid', isEqualTo: user.uid)
            .snapshots()
            .listen((snapshot) {
            _vaults = [];
            _vaults.addAll(sharedVaults);
            initVaultItems();
          for (final document in snapshot.docs) {
            List<DictItem> items = (document['items'] as List<dynamic>).map((item) =>  
                DictItem(word: item['word'], definitions: (item['definitions'] as List<dynamic>).map((e) => e.toString()).toList(),
                synonyms: (item['synonyms'] as List<dynamic>).map((e) => e.toString()).toList())).toList();
            _vaults.add(Vault(uid:document['uid'] as String, name: document['name'] as String, vaultitems: items, fbusers: []));
            _vaultItems.add(UserVault(name: document['name'] as String));
          }
          notifyListeners();
        });
        notifyListeners();
      }else {
        _loginState = ApplicationLoginState.emailAddress;
        _vaults = [];
        _vaultItems = [];
        _vaultItemSubscription?.cancel();
        notifyListeners();
      }
      notifyListeners();
    });
    notifyListeners();
  }
  

  void startLoginFlow() {
    _loginState = ApplicationLoginState.emailAddress;
    notifyListeners();
  }

  void addVaultItems(int index, DictItem vaultItem) {
    if (index != -1) {
      _vaults[index].vaultitems.add(vaultItem);
      // todo -> check if this vault is shared, if so run another function
      //todo -> add vault owner and is shared props to a vault
      updateFireStoreVaultItem(_vaults[index]);
    }
    notifyListeners();
  }

  void addGridChild(String vaultName, String vaultUid, BuildContext context) {
    _vaults.add(Vault(uid: vaultUid, name: vaultName, vaultitems: [], fbusers: []));
    _vaultItems.add(Padding(
      padding: const EdgeInsets.all(10.0),
      child: GestureDetector(
        onTap: () {
          Vault vault = Vault(uid: vaultUid, name: vaultName, vaultitems: [], fbusers: []);
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => VaultView(vault: vault, vaultIndex: _vaultItems.length + 1)));
        },
        child: Container(
          width: 30.0,
          height: 50.0,
          decoration: const BoxDecoration(
              color: Color.fromARGB(255, 20, 74, 118),
              borderRadius: BorderRadius.all(Radius.circular(20))),
          child: Center(
              child: Text(vaultName,
                  style: const TextStyle(fontSize: 25, color: Colors.white))),
        ),
      ),
    ));
    notifyListeners();
  }

  Future<void> verifyEmail(String email,
      void Function(FirebaseAuthException e) errorCallback) async {
    try {
      var methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.contains('password')) {
        _loginState = ApplicationLoginState.password;
      } else {
        _loginState = ApplicationLoginState.register;
      }
      _email = email;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  Future<void> signInWithEmailAndPassword(
    String email,
    String password,
    void Function(FirebaseAuthException e) errorCallback,
  ) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      getFriendsList();
      _displayName = currentUser?.displayName;
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  void cancelRegistration() {
    _loginState = ApplicationLoginState.emailAddress;
    notifyListeners();
  }

  Future<void> registerAccount(
      String email,
      String displayName,
      String password,
      void Function(FirebaseAuthException e) errorCallback) async {
    try {
      var credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await credential.user!.updateDisplayName(displayName);
      await currentUser?.reload();
      addUserToFireStore();
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  void signOut() {
    _loginState = ApplicationLoginState.emailAddress;
    currentUser = null;
    currentFriends = [];
    FirebaseAuth.instance.signOut();
    notifyListeners();
  }

  // Interacting with the FireStore vaults
  Future<void> addVaultToFireStore(Vault item, BuildContext context) {
    addGridChild(item.name, currentUser!.uid, context);
    return FirebaseFirestore.instance
        .collection('vaults')
        .doc(item.name + '_' + currentUser!.uid)
        .set(<String, dynamic>{
          'name': item.name,
          'uid': currentUser!.uid,
          'items': [],
          'sharedUsers': []
        });
  }

  dynamic createSavableWordList(Vault vault) {
    List<dynamic> result = [];
    for (int i = 0;i<vault.vaultitems.length;i++) {
      result.add({
        'word': vault.vaultitems[i].word,
        'definitions': vault.vaultitems[i].definitions,
        'synonyms': vault.vaultitems[i].synonyms
      });
    }
    return result;
  }

  //This is where the uid will not match
  Future<void> updateFireStoreVaultItem(Vault vault){
    List<dynamic> saveList = createSavableWordList(vault);
    return FirebaseFirestore.instance
      .collection('vaults')
      .doc(vault.name + '_' + vault.uid)
      .update({'items': saveList});
  }

  // FUNCTIONS FOR ADDING FRIENDS -------------------------------------------*

  //Creating user collection if this fails change back to DocumentReference
  Future<void> addUserToFireStore() {
    return FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser!.uid)
      .set(<String, dynamic>{
        'name': currentUser!.displayName,
        'email':currentUser!.email,
        'uid': currentUser!.uid,
        'friends': [],
      });
  }

  //get a user from thr user collection
  Future<void> updateFriendList(String friendEmail) async{
    await FirebaseFirestore.instance
    .collection('users')
    .get()
    .then((QuerySnapshot querySnapshot) async {
      for (var doc in querySnapshot.docs){
        if (friendEmail == doc["email"] && friendEmail != currentUser!.email){
          await listUpdater(doc["name"], doc["uid"]);
          return;
        }
      }
      addFriend = false;
      notifyListeners();
    });
  }

  //update user collection with new friends
  Future<void> listUpdater (String name, String uid) async{
    var obj = {"name": name, "uid": uid};
    List<dynamic> fl1 = [obj];
    var obj2 = {"name": currentUser!.displayName, "uid": currentUser!.uid};
    List<dynamic> fl2 = [obj2];
    await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser!.uid)
      .update({'friends': FieldValue.arrayUnion(fl1)});
    //Update the other friend as well
    await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .update({'friends': FieldValue.arrayUnion(fl2)});
    currentFriends.add(obj);
    addFriend = true;
    notifyListeners();
  }

  //get the users friends
  Future<void> getFriendsList () async{
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if(currentUser == null) return;

    await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser!.uid)
      .get()
      .then((DocumentSnapshot doc){
        if(doc.exists) {
          currentFriends = [];
          for(var i in doc['friends']){
            currentFriends.add({"name":i["name"] as String, "uid":i["uid"] as String});
          }
        }
      });
    notifyListeners();
  }

  // FUNCTIONS FOR SHARING VAULTS -------------------------------------------*

  //Add a shared vault for the user
  Future<void> addSharedUserToVault (String sharedUser, String sharedUserUid ,Vault vault){
    var sharedUserList = [{"name": sharedUser, "uid":sharedUserUid}];
    return FirebaseFirestore.instance
      .collection('vaults')
      .doc(vault.name + '_' + currentUser!.uid)
      .update({'sharedUsers': FieldValue.arrayUnion(sharedUserList)})
      .then((value) => notifyListeners());
  }
}
