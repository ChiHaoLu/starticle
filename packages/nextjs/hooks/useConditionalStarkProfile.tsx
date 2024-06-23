import { useStarkProfile } from "@starknet-react/core";
import * as chains from "@starknet-react/chains";
import scaffoldConfig from "~~/scaffold.config";

const useConditionalStarkProfile = (address: string | undefined) => {
  // Conditional hooks are not recommended, but in this case, it's the best approach to avoid issues on devnet.
  const profile = useStarkProfile({ address })
  return profile;
};

export default useConditionalStarkProfile;
