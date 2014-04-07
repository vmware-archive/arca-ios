#Copyright (C) 2013-2014 Pivotal Software, Inc.
#
#All rights reserved. This program and the accompanying materials
#are made available under the terms of the Apache License,
#Version 2.0 (the "License”); you may not use this file except in compliance
#with the License. You may obtain a copy of the License at
#
#http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#
#limitations under the License.
#
#Created by Adrian Kemp on 2013-12-18
# Build Phase
#   Here we are building the framework's static library for all of the required architectures

xcodebuild -target "ArcaBridge" -arch x86_64 -sdk iphonesimulator install
xcodebuild -target "ArcaBridge" -arch i386 -sdk iphonesimulator install
xcodebuild -target "ArcaBridge" -arch armv7 install
xcodebuild -target "ArcaBridge" -arch armv7s install

# Lipo Phase
#    Lipo is a tool that combines static libraries into "fat" libraries supporting multiple architectures

lipo "$INSTALL_PATH/$PRODUCT_NAME.framework/"*"-$PRODUCT_NAME" -create -output "$INSTALL_PATH/$PRODUCT_NAME.framework/$PRODUCT_NAME"

# Clean-up Phase
#   Once we've lipo'ed there is no benefit to having the individual libraries kicking around.

rm "$INSTALL_PATH/$PRODUCT_NAME.framework/"*"-$PRODUCT_NAME"
