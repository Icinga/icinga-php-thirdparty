<?php

namespace React\Promise;

// ExtendedPromiseInterface extends PromiseInterface and was removed in v3.
// This alias makes existing ExtendedPromiseInterface users compatible with the newest React\Promise.
class_alias(PromiseInterface::class, ExtendedPromiseInterface::class);
