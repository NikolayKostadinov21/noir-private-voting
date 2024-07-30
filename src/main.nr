contract Voting {
    use dep::aztec::prelude::{
        AztecAddress, FunctionSelector, NoteHeader, NoteInterface, NoteGetterOptions, PrivateContext,
        Map, PublicMutable, SharedImmutable
    };

    #[aztec(storage)]
    struct Storage {
        admin: PublicMutable<AztecAddress>, // admin can end vote
        tally: Map<Field, PublicMutable<Field>>, // we will store candidate as key and number of votes as value
        vote_ended: PublicMutable<bool>, // if the vote has terminated
        activate_at_block: SharedImmutable<u32>, // when people can start voting
    }

    #[aztec(public)]
    #[aztec(initializer)] // annotation to mark function as a constructor
    fn constructor(admin: AztecAddress) {
        storage.admin.write(admin);
        storage.vote_ended.write(false);
        storage.activate_at_block.initialize(context.block_number() as u32); // Intended to be only called once.
    }

    // 1. Everyone with an Aztec account gets a vote
    // 2. They can only vote once in this contract
    // 3. Who they are is private, but their actual vote is not
    #[aztec(private)] // expose private context
    fn cast_vote(candidate: Field) {
        // Below, we make sure to get our nullifier public key at a specific block.
        // By pinning the nullifier public key at a specific block,
        // rotating keys will have no effect on the nullifier being produced, and voting after will fail because the same nullifier is computed each time the user votes.
        let header_at_active_block = context.get_header_at(storage.activate_at_block.read_private());
        let msg_sender_npk_m_hash = header_at_active_block.get_npk_m_hash(&mut context, context.msg_sender());


        let secret = context.request_nsk_app(msg_sender_npk_m_hash); // get secret key of caller of function
        let nullifier = dep::std::hash::pedersen_hash([context.msg_sender().to_field(), secret]); // derive nullifier from sender and secret
        context.push_new_nullifier(nullifier, 0); // push nullifier
        Voting::at(context.this_address()).add_to_tally_public(candidate).enqueue(&mut context);
    }

    #[aztec(public)]
    #[aztec(inline)]
    fn add_to_tally_public(candidate: Field) {
        assert(storage.vote_ended.read() == false, "Voting has ended");
        let new_tally = storage.tally.at(candidate).read() + 1;
        storage.tally.at(candidate).write(new_tally);
    }

    #[aztec(public)]
    fn end_vote() {
        assert(storage.admin.read().eq(context.msg_sender()), "Only the Admin can end votes"); // Assert that the caller is the admin
        storage.vote_ended.write(true);
    }

    unconstrained fn get_vote(candidate: Field) -> pub Field {
        storage.tally.at(candidate).read()
    }
}
