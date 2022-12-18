import 'package:circle/phone_contacts_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';

import '../widgets/phone_contact_tile.dart';
import 'chat_core/util.dart';


class SearchContactsScreen extends StatefulWidget {
  const SearchContactsScreen({Key? key, required this.phoneContactsController}) : super(key: key);

  final PhoneContactsController phoneContactsController;
  @override
  State<SearchContactsScreen> createState() => _SearchContactsScreenState();
}

class _SearchContactsScreenState extends State<SearchContactsScreen> {

  @override
  void initState() {
    contacts = widget.phoneContactsController.allContacts;
    // TODO: implement initState
    super.initState();
  }

  final FocusNode _focusNode = FocusNode();

  TextEditingController searchController = TextEditingController();
  List<Contact> contacts = [];

  @override
  Widget build(BuildContext context) {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      // executes after build
    });




    return
      Scaffold(
        body: SafeArea(
          child: Scaffold(
            appBar: AppBar(title:  const Text(  "Search Contacts"),),
            body: Column(
              children: [
                const SizedBox(height: 25,),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: TextFormField(
                    focusNode: _focusNode,
                    onChanged: (value){
                      setState((){});
                    },
                    controller: searchController,
                    decoration:  const InputDecoration(
                        enabledBorder: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(),
                        labelText: "Search Contacts",
                        isDense: true
                    ),
                  ),
                ),
                const SizedBox(height: 10,),
                Expanded(
                  child: ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (context, index){
                            if(searchController.text.isEmpty || contacts[index].displayName.toLowerCase().startsWith(RegExp(searchController.text.toLowerCase().trim()))
                            || ( (index < widget.phoneContactsController.savedUsers.length) ?
                                widget.phoneContactsController.savedContacts[index].displayName.toLowerCase().startsWith(RegExp(searchController.text.toLowerCase().trim()))
                                : false
                                )

                            ){
                        if (index < widget.phoneContactsController.savedUsers.length) {
                          return PhoneContactTile(
                              contact: widget
                                  .phoneContactsController.savedContacts[index],
                              user: widget
                                  .phoneContactsController.savedUsers[index]);
                        }

                        return PhoneContactTile(
                          contact: contacts[index],
                        );
                      }
                            else{
                              return SizedBox();
                            }
                    }
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

}

