<template>
    <p>Contract Interaction</p>
    <h5>Contract is deployed at: <code>
        {{ address }}
    </code></h5>

</template>

<script>
export default {
    name: 'ContractInteraction',
    props: ["address"],
}
</script>
