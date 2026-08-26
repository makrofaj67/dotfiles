#pragma once

#include "Types.hpp"
#include <vector>
#include <string>

namespace FifoServer {

bool init();

void cleanup();

void drainCompleteLines();

void executeFifoBatch(const std::vector<SParsedCommand>& batch);

bool parseFifoLine(const std::string& line, SParsedCommand& cmd);

} // namespace FifoServer
