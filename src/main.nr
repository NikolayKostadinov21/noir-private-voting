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
}
